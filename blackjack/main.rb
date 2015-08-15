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
    if session[:player][:total] >= 21
      session[:stay] = true # flag to allow dealer to start hitting
      session[:result_msg]= "<div class = 'alert alert-error'> <h3 class = 'text-alert'> You have busted... </h3></div>"
    end
  end

  def dealers_turn
    while session[:dealer][:total] < 17
      deal!(:dealer)
      if_ace_adjust_total_by_ten(:dealer) if session[:dealer][:total] > 21
      erb :play
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
        if @player[:total] == 21
          session[:result_msg] = "<div class= 'alert alert-warning'><h3 class = 'text-warning'> You both have blackjacks, its' a push </h3> </div> "
          pay_win(0)
        end
        session[:result_msg] = "<div class= 'alert alert-error'><h3 class = 'text-alert'> The dealer has a Blackjack, you lost... </h3> </div>" if @player[:total] != 21
      else
        pay_win(1.5)
        session[:result_msg] = "<div class= 'alert alert-success'><h3 class = 'text-success'> You have a Blackjack!! You won $ #{session[:winning]} ! </h3> </div>"
      end
      return true
    else
      session[:result_msg] = ""
      return false
    end
  end

  def pay_win(multiplier)
    @pay = multiplier * session[:bet].to_f + session[:bet].to_f
    session[:winning] = @pay
    session[:player][:balance] += @pay
  end

  def find_winner
    if session[:dealer][:total] <= 21
      if session[:player][:total] == session[:dealer][:total]
        session[:result_msg] = "<div class = 'alert alert-warning'> <h3 class = 'text-warning'> It's a push </h3></div>"
        pay_win(0)
      end
      if session[:player][:total] > session[:dealer][:total]
        session[:result_msg] = "<div class = 'alert alert-success'> <h3 class = 'text-success'> You won! $#{session[:bet]} have been added to your balance </h3></div>"
        pay_win(1)
      end
      session[:result_msg] = "<div class = 'alert alert-error'> <h3 class = 'text-alert'> You lost... </h3></div>" if session[:player][:total] < session[:dealer][:total]
    else
      session[:result_msg] = "<div class = 'alert alert-success'> <h3 class = 'text-success'> You won! $#{session[:bet]} have been added to your balance </h3></div>"
      pay_win(1)
    end
    session[:winner] = true
  end

  def reset_game!
    session[:player].merge!(total: 0, ace: 0, cards_dealt: [])
    session[:dealer].merge!(total: 0, ace: 0, cards_dealt: [])
    session[:stay] = false
    session[:cards_dealt] = []
    session[:result_msg] = ""
    session[:blackjack] = false
    session[:winner] = false
  end

  def add_cards_dealt_to_deck
    session[:cards_dealt].each do |card|
      session[:deck].unshift(card)
    end
    session[:cards_dealt] = []
  end

  def update_balance
    session[:player][:balance] = session[:player][:balance].to_f - session[:bet].to_f
  end

end

get '/' do
  erb :index
end

post '/' do
  session[:player] = {name: params[:player_name], balance: 100, cards_dealt: [], total: 0, ace: 0 }
  session[:deck] = setup_initial_deck(1)
  session[:cards_dealt] = []
  session[:dealer] = {cards_dealt: [], total: 0, ace: 0 }
  redirect '/welcome'
end

get '/welcome' do
  erb :welcome
end

get '/play' do
  if session[:player][:name] == nil
    redirect '/'
  end
  if !session[:blackjack] && session[:stay] && session[:player][:total] <= 21
    dealers_turn
    find_winner
  end
  if session[:player][:balance] == 0 && session[:winner]
    erb :broke
  else
    erb :play
  end
end

get '/hit' do
  deal!(:player)
  redirect '/play'
end

post '/bet' do
  session[:bet] = params[:bet]
  update_balance
  add_cards_dealt_to_deck if !session[:cards_dealt].nil?
  reset_game!
  deal_two
  erb :play
end

get '/stay' do
  session[:stay] = true
  redirect '/play'
end

get '/test' do
  erb :test
end
