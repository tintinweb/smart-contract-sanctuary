/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.10;



// Part: OpenZeppelin/[email protected]/Context

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: Bet.sol

contract Betting is Ownable {
    enum Bet{EMPTY, ASKR, EMBLA,NIFL,MUSPELL,FAIRY,MECHA}
    struct User {
        address id;
        Bet bet;
        bool hasBet;
        uint256 amountBet;
        uint256 winningPercentage;  
    }
    address[] public Voters;
    mapping(address => User) public users; 
    address payable public contractAddress;
    Bet public finalResultIs;
    mapping(uint => address) public Winners;
    uint public winnerCount;
    User resetUser; 
    address nulladdress;
    event WinnerPayed(address indexed winner, uint256 amount);
    uint public resplendent;


    constructor() public{
        contractAddress = payable(address(this));
        resplendent =1;
        finalResultIs = Bet.EMPTY;
        winnerCount = 0;
        nulladdress = 0x0000000000000000000000000000000000000000;
        resetUser = User(nulladdress,Bet(0), false, 0,0);        
    }
    
    function placeBet(Bet _bet) public payable{
        require(!users[msg.sender].hasBet, "User has already bet!");
        
        User memory user = User(msg.sender,_bet,true,msg.value, 0);
        Voters.push(msg.sender);
        users[msg.sender] = user;
    }
    
    function getPrizeMoney() public view returns(uint256){
        return(contractAddress.balance * 99)/100; //Contract collects a 1% fee
    }
    
    function setFinalResult(uint _resplendent) private {
        finalResultIs = Bet(_resplendent);
    }

    function sortPlayersByBetsAndGetWinners() private {
        uint256 totalAmountBetByWinners = 0;
        winnerCount = 0;
        setFinalResult(resplendent);
        

        for(uint256 i =0; i < Voters.length; i++){
            if(users[Voters[i]].bet == finalResultIs){
                totalAmountBetByWinners =totalAmountBetByWinners+ users[Voters[i]].amountBet;
                Winners[winnerCount] = users[Voters[i]].id;
                winnerCount++;
            }
        }
        for (uint256 j = 0; j < winnerCount; j++) {    
            users[Winners[j]].winningPercentage = (users[Winners[j]].amountBet*100) / totalAmountBetByWinners;
        }
    }

    function getResplendentValue(uint8 _num) public onlyOwner {
        resplendent = _num;
    }
    
    function payWinners() private {
        require(contractAddress.balance >= 0 wei, "No bets placed");
        sortPlayersByBetsAndGetWinners();
        require(winnerCount > 0, "No winners this round");
        uint256 prizemoney = getPrizeMoney();

        for (uint256 i = 0; i < winnerCount; i++) {
            uint256 amountForWinner = (users[Winners[i]].winningPercentage * prizemoney)/100;
            payout(payable(Winners[i]),amountForWinner);
        }
    }    
    
    function payout(address payable _to, uint256 _amount) private {
        (bool success,) = _to.call{value:_amount}("");
        require(success, "Failed to pay winner");
        emit WinnerPayed(_to, _amount);
    }
    
    function CleanWinnningMapping() private{
        for (uint i = 0; i < winnerCount; i++){
            Winners[i] = nulladdress;
        }

        winnerCount = 0;

        for(uint j = 0; j < Voters.length; j++)
        {
            users[Voters[j]] = resetUser;
        }

        delete Voters;
    }

    function finalResult() public onlyOwner {
        payWinners();
        //CleanWinnningMapping();
    }
    
}