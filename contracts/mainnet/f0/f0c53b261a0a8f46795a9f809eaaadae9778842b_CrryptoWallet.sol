pragma solidity ^0.4.25;

/*
* CryptoMiningWar - Blockchain-based strategy game
* Author: InspiGames
* Website: https://cryptominingwar.github.io/
*/

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool /*_isContractMiniGame*/ );
    function getCurrentReward(address /*_addr*/) external pure returns( uint256 /*_currentReward*/ );
    function withdrawReward(address /*_addr*/) external;
    function fallback() external payable;
}
contract CrryptoWallet {
	using SafeMath for uint256;

	address public administrator;
    uint256 public totalContractMiniGame = 0;

    mapping(address => bool)   public miniGames; 
    mapping(uint256 => address) public miniGameAddress;

    modifier onlyContractsMiniGame() 
    {
        require(miniGames[msg.sender] == true);
        _;
    }
    event Withdraw(address _addr, uint256 _eth);

    constructor() public {
        administrator = msg.sender;
    }
    function () public payable
    {
        
    }
    /** 
    * @dev MainContract used this function to verify game&#39;s contract
    */
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }
    function isWalletContract() public pure returns(bool)
    {
        return true;
    }
    function upgrade(address addr) public 
    {
        require(administrator == msg.sender);

        selfdestruct(addr);
    }
    /** 
    * @dev Main Contract call this function to setup mini game.
    */
    function setupMiniGame( uint256 /*_miningWarRoundNumber*/, uint256 /*_miningWarDeadline*/) public
    {
    }
    //--------------------------------------------------------------------------
    // SETTING CONTRACT MINI GAME 
    //--------------------------------------------------------------------------
    function setContractsMiniGame( address _addr ) public  
    {
        require(administrator == msg.sender);

        MiniGameInterface MiniGame = MiniGameInterface( _addr );

        if ( miniGames[_addr] == false ) {
            miniGames[_addr] = true;
            miniGameAddress[totalContractMiniGame] = _addr;
            totalContractMiniGame = totalContractMiniGame + 1;
        }
    }
    /**
    * @dev remove mini game contract from main contract
    * @param _addr mini game contract address
    */
    function removeContractMiniGame(address _addr) public 
    {
        require(administrator == msg.sender);

        miniGames[_addr] = false;
    }
   
    
    // --------------------------------------------------------------------------------------------------------------
    // CALL FUNCTION
    // --------------------------------------------------------------------------------------------------------------
    function getCurrentReward(address _addr) public view returns(uint256 _currentReward)
    {
        for(uint256 idx = 0; idx < totalContractMiniGame; idx++) {
            if (miniGames[miniGameAddress[idx]] == true) {
                MiniGameInterface MiniGame = MiniGameInterface(miniGameAddress[idx]);
                _currentReward += MiniGame.getCurrentReward(_addr);
            }
        }
    }

    function withdrawReward() public 
    {
        for(uint256 idx = 0; idx < totalContractMiniGame; idx++) {
            if (miniGames[miniGameAddress[idx]] == true) {
                MiniGameInterface MiniGame = MiniGameInterface(miniGameAddress[idx]);
                MiniGame.withdrawReward(msg.sender);
            }
        }
    }
}