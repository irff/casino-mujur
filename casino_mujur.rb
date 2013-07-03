require 'yaml'

class Casino
  def initialize
    @score = { "A" => 1, "B" => 2, "C" => 3, "8" => 5, "X" => 10}
  end

  def generate
    for i in (0...3)
      for j in (0...3)
        r = Random.rand(0..22)
        if (0..9).include?(r) then tmp = 'A'
        elsif (10..15).include?(r) then tmp = 'B'
        elsif (16..19).include?(r) then tmp = 'C'
        elsif (19..21).include?(r) then tmp = '8'
        else tmp = 'X' end
        $a[i][j] = tmp
      end
    end
  end

  def print_table
    for i in (0...3)
      print " "*35
      for j in (0...3)
        print "#{$a[i][j]} "
      end
      puts
    end
  end

  def get_score(bet)
    your_score = 0
    if all != 0 then your_score = all
    elsif center !=0 then your_score = center
    else your_score = horizontal + vertical + diagonal
    end
    
    return your_score*bet
  end
  
  private
  def score_by_letter(letter, param)
    return @score[letter]*param
  end
  
  #eliminate duplicates in the array
  def squash(arr, param)
    x = arr.uniq
    return x.size == 1 ? score_by_letter(x[0],param) : 0
  end

  def horizontal
    horizontal_score = 0
    $a.each { |x|
      horizontal_score += squash(x,1)
    }
    return horizontal_score
  end

  def vertical
    vertical_score = 0
    for i in (0...3)
      x = []
      for j in (0...3)
        x << $a[j][i]
      end
      vertical_score += squash(x, 1)
    end
    return vertical_score
  end

  def diagonal
    diagonal_score = 0
    x = []
    y = []
    
    for i in (0...3)
      x << $a[i][i]
      y << $a[2-i][i]
    end
    
    diagonal_score += squash(x,1)
    diagonal_score += squash(y,1)
    
    return diagonal_score
  end

  def all
    x = $a.flatten
    return squash(x,10)
  end

  def center
    center_score = 0
    x = $a.flatten
    y = x.uniq
    if y.size == 2
      if x.count(y[0]) == 8 and x.count(y[1]) == 1
        center_score = score_by_letter(y[0],20)
      elsif x.count(y[1]) == 8 and x.count(y[0]) == 1
        center_score = score_by_letter(y[1],20)
      end
    end
    return center_score
  end
end

class Player
  attr_accessor :money
  def initialize(duit = 20)
    @our_casino = Casino.new
    @money      = duit
    @bet        = 1
    @mode       = :normal
    @lower      = 1
    @upper      = 10
    @turn       = 1
    @turn_limit = 0
    
    f = File.open('high_scores.yml')
    @high_scores = YAML.load(f)
    f.close
  end
  
  def select_mode
    mode_list   = [:normal, :easy, :limited, :growing, :limited_easy, :growing_easy]
    system('cls')
    puts ' '*35 + "Mode List :"
    puts ' '*35 + "  1. Normal Mode"
    puts ' '*35 + "  2. Easy Mode"
    puts ' '*35 + "  3. Limited Normal Mode"
    puts ' '*35 + "  4. Growing Normal Mode"
    puts ' '*35 + "  5. Limited Easy Mode"
    puts ' '*35 + "  6. Growing Easy Mode"
    puts ' '*35 + "  7. Help"
    puts ' '*35 + "  8. Exit"
    print ' '*35 + "Select Mode : "
    player_mode = gets.chomp.to_i
    
    if player_mode == 8 then exit end
    if player_mode.between?(1,6)
      if player_mode == 3 or player_mode == 5
        while @turn_limit == 0
          system('cls')
          print ' '*35 + "Set turn limit : "
          @turn_limit = gets.chomp.to_i
        end
      end
      @mode = mode_list[player_mode - 1]
    elsif player_mode == 7
      show_help
      select_mode
    else select_mode
    end
  end
  
  def main_loop
    while true
      mode_specific_commands
      
      if money <= 0
        system('cls')
        puts " "*35 + "Game Over..."
        show_high_scores
        exit
      end
      
      show_header
      print " "*25 + "Place your bet (#{@lower}..#{@upper}) : $ "
      
      @bet = gets.chomp
      
      if @bet == "quit" then exit
      elsif @bet == "save" then save
      elsif @bet == "highscores" then show_high_scores
      else
        @bet = @bet.to_i
        bet_limit = @bet
        bet_limit = 2*@bet if @mode == :normal or @mode == :limited or @mode == :growing
        play(@bet) if @bet.between?(@lower,@upper) and bet_limit <= money
      end
      
    end
  end
  
  private
  
  def play(bet)
    @our_casino.generate
    score = @our_casino.get_score(bet)
    @money = score_by_mode(score, bet)
    
    show_header
    puts
    @our_casino.print_table
    puts " "*30  +"Your score = #{score}"
    gets
    @turn += 1
  end

  def score_by_mode(score, bet)
      money_lost = bet
      money_lost = 2 * bet if [:normal, :limited, :growing].include?(@mode)
      
      if score == 0 then return @money - money_lost
      else return @money - bet + score
      end
  end
  
  def mode_specific_commands
    if (@mode == :limited or @mode == :limited_easy) and @turn > @turn_limit
      system('cls')
      puts ' '*25 + "Turn limit reached"
      gets
      save
    end
    
    if @mode == :growing or @mode == :growing_easy
      grow
    end
  end

  #only for growing mode
  def grow
    if @money <= 100
      @lower = 1;
      @upper = 10;
    else
      @lower = (@money-100)/10 + 1
      @upper = @lower + 10
    end
  end
  
  def show_turn(saving = false)
    if @mode == :limited or @mode == :limited_easy
      puts ' '*25 + "Turn number            :   #{saving ? @turn - 1 : @turn}"
    end
  end
  
  def show_header(saving = false)
    system('cls')
    puts " "*25+"Your money             : $ #{@money}"
    show_turn(saving)
  end
  
  def save
    return if @high_scores[@mode][-1][0] >= @money
    name = ""
    while name.empty?
      show_header(true)
      print " "*25+"What's your name       : " 
      name = gets.chomp
    end
    @high_scores[@mode].pop
    @high_scores[@mode] << [@money, name]
    @high_scores[@mode].sort!
    @high_scores[@mode].reverse!
    
    f = File.new('high_scores.yml', 'w')
    f.write(@high_scores.to_yaml)
    f.close
    
    system('cls')
    show_high_scores
    exit
  end
  
  def show_high_scores
    limit = @high_scores[@mode].size
    limit = 5 if limit > 5
    puts "\n" + " "*35 + "Hall of Fame\n\n"
    for i in (0...limit)
      puts " "*35 + "#{i+1} - #{@high_scores[@mode][i][0]} #{@high_scores[@mode][i][1]}"
    end
    gets
  end
  
  def show_help
    system('cls')
    
    help_text = <<heredocs
Mode List :
  1. Normal Mode
     Money Used = 2 times your bet, if you scored 0
     Money Used = your bet, if you scored more than 0
  2. Easy Mode
     Money Used = your bet, if you scored 0
     Money Used = your bet, if you scored more than 0
  3. Limited Mode
     Normal Mode with limited number of turns
  4. Growing Mode
     Normal mode
     The low and high bet limit will constantly increase as your money does
  5. Limited Easy Mode
     Easy Mode with limited number of turns
  6. Growing Easy Mode
     Easy mode with growing bet limit

In-game Commands :
  1. Type `highscores' to view current mode's highscores
  2. Type `save' to save your score and exit
  3. Type `quit' to exit the game
heredocs

    credits= <<heredocs
Credits :
  Casino Mujur 1.0
  Build May 27, 2012
  2012 (c)
  The Irfan3 Studio
heredocs
    
    puts help_text
    gets
    puts credits
    gets
  end
end

$a = [ [0,0,0],
       [0,0,0],
       [0,0,0] ]
our_player  = Player.new
our_player.select_mode
our_player.main_loop