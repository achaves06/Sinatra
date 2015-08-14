require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => '123456'

helpers do

  def setup_initial_deck(num_decks)
    deck =%w(ace 2 3 4 5 6 7 8 9 10 jack queen king).product(%w(hearts diamonds clubs spades))
    playable_deck = deck * num_decks
    playable_deck.shuffle!
  end

  def deal!(player)
    card = session[:deck].pop
    session[:cards_dealt] << card
    session[player][:cards_dealt] << card
    session[player][:total]   = calculate_total(player, card)
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

  def blackjack(user, dealer)
    if user[:total] == 21 || dealer[:total] == 21
      if dealer[:total] == 21
        show_cards(dealer)
        puts "You both have blackjacks, its' a push" if user[:total] == 21
        puts "Dealer blackjack, you lost..." if user[:total] != 21
      else
        puts "\nBlackjack!! You win!"
      end
      return true
    else
      return false
    end
  end

  def find_winner(user,dealer)
    if dealer[:total] <= 21
      puts "\n It's a push" if user[:total] == dealer[:total]
      puts "\n You win!" if user[:total] > dealer[:total]
      puts "\n You lost..." if user[:total] < dealer[:total]
    else
      puts "You win"
    end
  end

  def reset_counts!(user, dealer)
    user.merge!(total: 0, ace: 0, cards: [])
    dealer.merge!(total: 0, ace: 0, cards: [])
  end

  def add_cards_dealt_to_deck(cards_dealt,playable_deck)
    playable_deck.unshift(cards_dealt)
    cards_dealt = []
    return cards_dealt, playable_deck
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
  session[:cards_dealt] = []
  session[:winner]=false
  redirect '/deal'
end

get '/deal' do
  2.times do
    deal!(:player)
    deal!(:dealer)
  end
  erb :play
end
