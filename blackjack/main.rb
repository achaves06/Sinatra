require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '123456'

helpers do

  configure do
    set :start_time, Time.now
  end

  before do
    last_modified settings.start_time
    etag settings.start_time.to_s
    cache_control
  end

  def setup_initial_deck(num_decks)
    deck =%w(ace 2 3 4 5 6 7 8 9 10 jack queen king).product(%w(hearts diamonds clubs spades))
    playable_deck = deck * num_decks
    playable_deck.shuffle!
  end

  def deal_two
    2.times do
      deal!(:player)
      deal!(:dealer)
    end
    blackjack
  end

  def deal!(player)
    card = session[:deck].pop
    session[:cards_dealt] << card
    session[player][:cards_dealt] << card
    session[player][:total]   = calculate_total(player, card)
    session[:stay] = true if session[player][:total] >= 21 # flag to allow dealer to start hitting
  end

  def dealers_turn
    while session[:dealer][:total] < 17
      deal!(:dealer)
      if_ace_adjust_total_by_ten(:dealer) if session[:dealer][:total] > 21
      erb :deal
    end
  end

  def calculate_total(player, card)
    card_rank = card[0]
    if card_rank == "ace"
      session[player][:total] <= 10 ? session[player][:total] += 11 : session[player][:total] += 1
      session[player][:ace] += 1
    elsif card_rank == "jack" or card_rank == "queen" or card_rank == "king"
      session[player][:total] += 10
    else
      session[player][:total] += card_rank.to_i
    end
    if_ace_adjust_total_by_ten(player) if session[player][:total] > 21
    return session[player][:total] # if I don't return it, the session variable does not get updated
  end

  def if_ace_adjust_total_by_ten(player)
    if session[player][:ace]== 0
      puts "\n #{session[player][:name]} busted..."
    elsif session[player][:ace] >= 1 #convert their ace value from 11 to 1 and lower their ace count
      session[player][:total] += -10
      session[player][:ace] += -1
    end
  end

  def blackjack
    @player = session[:player]
    @dealer = session[:dealer]
    if @player[:total] == 21 || @dealer[:total] == 21
      session[:blackjack] == true
      if @dealer[:total] == 21
        session[:stay] = true #this will show the dealers cards
        session[:result_msg] = "<p class = 'text-warning'> You both have blackjacks, its' a push </p> " if @player[:total] == 21
        session[:result_msg] = "<p class = 'text-alert'> Dealer blackjack, you lost... </p>" if @player[:total] != 21
      else
        pay_win(1.5)
        session[:result_msg] = "<p class = 'text-success'> Blackjack!! You won $ #{session[:winning]} %> ! </p>"
      end
      return true
    else
      session[:result_msg] = ""
      return false
    end
  end

  def pay_win(multiplier)
    @pay = multiplier * session[:bet].to_f
    session[:winning] = @pay
    session[:player][:balance] += @pay
  end

  def find_winner
    if session[:dealer][:total] <= 21
      session[:result_msg] = "<p class = 'text-warning'> It's a push </p>" if session[:player][:total] == session[:dealer][:total]
      if session[:player][:total] > session[:dealer][:total]
        session[:result_msg] = "<p class = 'text-success'> You win! </p>"
        pay_win(1)
      end
      session[:result_msg] = "<p class = 'text-alert'> You lost... </p>" if session[:player][:total] < session[:dealer][:total]
    else
      session[:result_msg] = "<p class = 'text-success'> You win! </p>"
      pay_win(1)
    end
  end

  def reset_counts!
    session[:player].merge!(total: 0, ace: 0, cards_dealt: [])
    session[:dealer].merge!(total: 0, ace: 0, cards_dealt: [])
    session[:stay] = false
    session[:cards_dealt] = []
    session[:result_msg] = ""
  end

  def add_cards_dealt_to_deck
    session[:cards_dealt].each do |card|
      session[:deck].unshift(card)
    end
    session[:cards_dealt] = []
  end

  def update_balance
    session[:balance] = session[:balance].to_f - session[:bet].to_f
  end



end

get '/' do
  erb :index
end

post '/' do
  session[:player] = {name: params[:player_name], balance: 100, cards_dealt: [], total: 0, ace: 0 }
  session[:deck] = setup_initial_deck(1)
  redirect '/welcome'
end

get '/welcome' do
  erb :welcome
end

post '/welcome' do
  session[:bet] = params[:bet]
  session[:balance] = session[:balance].to_f - session[:bet].to_f
  session[:dealer] = {name: "Computer", cards_dealt: [], total: 0, ace:0}
  session[:stay] = false
  session[:cards_dealt] = []
  session[:winner]=false
  deal_two
  redirect '/deal'
end

get '/deal' do
  if !blackjack && session[:stay] && session[:player][:total] <= 21
    dealers_turn
    find_winner
  end
  erb :deal
end

get '/hit' do
  deal!(:player)
  redirect '/deal'
end

post '/bet' do
  session[:bet] = params[:bet]
  add_cards_dealt_to_deck
  reset_counts!
  update_balance
  deal_two
  erb :deal
end

get '/stay' do
  session[:stay] = true
  redirect '/deal'
end
