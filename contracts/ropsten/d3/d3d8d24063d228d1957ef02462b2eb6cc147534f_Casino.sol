pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Token{
    using SafeMath for uint256;
    
    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;
    address public tokenOwnerAdderss;
    address public casinoAddress;
    
    modifier onlyBy(address _owner){
        require(msg.sender == _owner);
        _;
    }
    
    constructor(address _tokenOwner) public {
        totalSupply = 0;
        tokenOwnerAdderss = _tokenOwner;
        casinoAddress = msg.sender;
    }
    
    function transfer(address _to, uint256 _value) public returns(bool){
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        
        return true;
    }
    
    function transferByCasino(address _from, address _to, uint256 _value) public onlyBy(casinoAddress) returns(bool){
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        require(balanceOf[_from] >= _value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        
        return true;
    }
    
    function mint(address _to, uint256 _value) public onlyBy(tokenOwnerAdderss){
        require(balanceOf[_to].add(_value) >= balanceOf[_to]);
        balanceOf[_to] = balanceOf[_to].add(_value);
        totalSupply = totalSupply.sub(_value);
    }
    
}

contract Casino{
    using SafeMath for uint256;
    
    struct Option{
        uint optionReward; 
        mapping (address => uint256) playerBetInfo;
    }
    
    Token token;
    address public tokenAddress;
    address public casinoOwnerAdderss;
    uint256 public bettingTime;
    bool public winnerRevealed;
    
    uint256 public totalReward;
    Option[2] options;
    
    uint256 public winner;
    
    event WinnerIs(uint256 _winner);
    event BetSuccess(address _player, uint256 _option, uint256 _value);
    event GetReward(address _player, uint256 _reward);
    
    
    modifier onlyBy(address _owner){
        require(msg.sender == _owner);
        _;
    }

    // Stage 0: Create
    // Initialize
    constructor(uint256 _bettingTimeInMinutes) public {
        casinoOwnerAdderss = msg.sender;
        bettingTime = now.add(_bettingTimeInMinutes * 1 minutes);
        winnerRevealed = false;

        tokenAddress = new Token(msg.sender);
        token = Token(tokenAddress);    
    }
    
    // Stage 1: Betting
    function bet(uint256 _option, uint256 _value) public returns (bool){
        require(now <= bettingTime);
        require(_option < options.length);
        require(token.transferByCasino(msg.sender, this, _value));
        
        options[_option].playerBetInfo[msg.sender] = options[_option].playerBetInfo[msg.sender].add(_value);
        options[_option].optionReward = options[_option].optionReward.add(_value);
        totalReward = totalReward.add(_value);
        
        emit BetSuccess(msg.sender, _option, _value);
        return true;
    }
    
    // Stage 2: Getting Result
    function revealWinner() public {
        require(now > bettingTime);
        require(!winnerRevealed);
        winner = uint(keccak256(abi.encodePacked(block.timestamp))) % 2;
        winnerRevealed = true;

        emit WinnerIs(winner);
    }
    
    // Stage 3: Claim the reward
    function claimReward() public returns (bool){
        require(winnerRevealed);
        assert(winner < options.length);
        require(options[winner].playerBetInfo[msg.sender] != 0);
        
        uint reward = totalReward.mul(options[winner].playerBetInfo[msg.sender].div(options[winner].optionReward));
        options[winner].playerBetInfo[msg.sender] = 0;
        require(token.transfer(msg.sender, reward));
        
        emit GetReward(msg.sender, reward);
        return true;
    } 
    
    // Owner function
    function setBettingTime(uint256 _newBettingTimeInSecond) public onlyBy(casinoOwnerAdderss){
        bettingTime = _newBettingTimeInSecond;
    }

    // Helper function
    function showWinner() view public returns(string){
        if(!winnerRevealed) return "Waiting for a winner";
        else{
            require(winner == 0 || winner == 1);
            
            if(winner == 0) return "The winner is number 0.";
            else if(winner == 1) return "The winner is number 1.";
        }
    }
    
    function showPlayerBetInfo(uint256 _option, address _address) view public returns(uint256 _amount){
	    _amount = options[_option].playerBetInfo[_address];
	}
}