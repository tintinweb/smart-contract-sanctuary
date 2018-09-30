pragma solidity ^0.4.24;

/*
  @author Yumerium Ltd
*/
contract YDistribution {
    using SafeMath for uint256;
    ERC20 public yumerium;
    address public yumo;
    address public teamWallet;
    address public creator;

    mapping(address => bool) public registeredHolders;
    mapping(uint256 => uint256) public ethRaisedForEachRounds;
    address[] public tokenHolders;
    uint256 public currentRound;

    constructor(address _teamWallet, address _yumerium, address _yumo_address) public {
        yumerium = ERC20(_yumerium);
        teamWallet = _teamWallet;
        creator = msg.sender;
        yumo = _yumo_address;
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator, "Changed the creator");
        creator = _creator;
    }
    // change wallet address
    function changeTeamWallet(address _wallet) external {
        require(msg.sender==creator, "You are not a creator!");
        teamWallet = _wallet;
    }
    // change yum address
    function changeYUMAddress(address _token_address) external {
        require(msg.sender==creator, "You are not a creator!");
        yumerium = ERC20(_token_address);
    }
    // change yumo address
    function changeYUMOAddress(address _yumo) external {
        require(msg.sender==creator, "You are not a creator!");
        yumo = _yumo;
    }

    function addHolder(address holder) external {
        require(msg.sender==creator || msg.sender==yumo, "You are not allowed to call this function!");
        if (!registeredHolders[msg.sender]) {
            registeredHolders[msg.sender] = true;
            tokenHolders.push(holder);
        }
    }

    function receiveToken() external payable {
        ethRaisedForEachRounds[currentRound] = ethRaisedForEachRounds[currentRound].add(msg.value);
    }

    function gameOver() external {
        require(msg.sender==creator || msg.sender==yumo, "You are not allowed to call this function!");
        uint256 totlaETH = address(this).balance;
        for (uint256 i = 0; i < tokenHolders.length; i++)
        {
            address holder = tokenHolders[i];
            uint256 ethToGive = totlaETH.mul(yumerium.balanceOf(holder))
                .div(yumerium.balanceOf(address(yumerium)));
            uint256 balance = address(this).balance;
            if (balance != 0)
            {
                if (ethToGive >= balance)
                {
                    ethToGive = balance;
                }
                if (ethToGive != 0)
                {
                    holder.transfer(ethToGive);
                }
            }
        }
        if (address(this).balance > 0)
            teamWallet.transfer(address(this).balance);

        currentRound++;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {
    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
}