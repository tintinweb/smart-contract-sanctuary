/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract iBet is Ownable , ReentrancyGuard {
    
   using SafeMath for uint256;
    uint256 public treasuryFee = 400; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)

   uint256 public minimum;
   address[] public playersID;
  
   struct Bet {
      uint256 id;
      string name1;
      string name2;
      uint16 gameWinner;
      uint256 totalbets;
      uint256 totalBetsOne;
      uint256 totalBetsTwo;
      uint256 closeTime;
      mapping(address => Player) playerInfo;
      address payable [] playersID;
   }
   
   struct Player {
      uint256 amt;
      uint16 selected;
      bool betted;
      bool claimed;
   }
    

   mapping(uint256 => Bet) public bets;
    
   uint256 currentBet;
    
    fallback() external payable {
        
    }
    
    receive() external payable {
        // custom function code
    }
    
   constructor() {
      minimum = 1 wei;
   }
   
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }
    
    /**
     * @notice Transfer BNB in a safe way
     * @param to: address to transfer BNB to
     * @param value: BNB amount to transfer (in wei)
     */
    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }
    
     /**
     * @notice Returns true if `account` is a contract.
     * @param account: account address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function withdraw(uint256 amount) external onlyOwner{
        _safeTransferBNB(owner(), amount);
    }
    
        /**
     * @notice Set treasury fee
     * @dev Callable by admin
     */
    function setTreasuryFee(uint256 _treasuryFee) external onlyOwner{
        treasuryFee = _treasuryFee;
    }

    
    function createBet(string memory name1,string memory name2,uint256 closeTime) public onlyOwner{
      currentBet++;
      bets[currentBet].id = currentBet;
      bets[currentBet].name1 = name1;
      bets[currentBet].name2 = name2;
      bets[currentBet].closeTime = closeTime;
    }


   function bet(uint8 selected , uint256 betId) public payable {
      require(betId > 0 && betId <= currentBet, "betId > 0 && betId <= currentBet" );
      require(!bets[betId].playerInfo[msg.sender].betted && bets[betId].closeTime > block.timestamp, "!bets[betId].playerInfo[msg.sender].betted && bets[betId].closeTime > block.timestamp" );
      require(msg.value >= minimum, "msg.value >= minimum");
      bets[betId].totalbets++;
      bets[betId].playerInfo[msg.sender].amt = msg.value;
      bets[betId].playerInfo[msg.sender].selected = selected;
      bets[betId].playerInfo[msg.sender].betted = true;

      if (selected == 1){
          bets[betId].totalBetsOne += msg.value;
      }else{
          bets[betId].totalBetsTwo += msg.value;
      }
      
      playersID.push(msg.sender);
    }
    
    function claim(uint256 betId) external nonReentrant notContract {
        require(betId > 0 && betId <= currentBet, "betId > 0 && betId <= currentBet" );
        require(bets[betId].gameWinner > 0 && bets[betId].gameWinner==bets[betId].playerInfo[msg.sender].selected, "bets[betId].gameWinner > 0 && bets[betId].gameWinner==bets[betId].playerInfo[msg.sender].selected");
        require(!bets[betId].playerInfo[msg.sender].claimed, "!bets[betId].playerInfo[msg.sender].claimed" );
         uint256 totalWin = 0;
         uint256 totalLost = 0;
        
          if (bets[betId].gameWinner == 1 ){
             totalWin = bets[betId].totalBetsOne;
             totalLost = bets[betId].totalBetsTwo;
          } else {
              totalWin = bets[betId].totalBetsTwo;
              totalLost = bets[betId].totalBetsOne;
          }
          

         uint256 bet_amount = bets[betId].playerInfo[msg.sender].amt;
         uint256 profite = 0;
         if(totalLost == 0){
            profite = bet_amount;
         }else{
             profite = (bet_amount * (totalLost + totalWin)) /  totalWin ;
         }
        
         
         uint256 fee =profite.mul(treasuryFee)/ 10000;
        
        _safeTransferBNB(msg.sender, profite - fee);
        _safeTransferBNB(owner(), fee);
        
        bets[betId].playerInfo[msg.sender].claimed = true;
    }
    
    function setWinner(uint16 _winner , uint256 betId) public onlyOwner{
       
       require(betId > 0 && betId <= currentBet, "betId > 0 && betId <= currentBet" );
       require(bets[betId].closeTime < block.timestamp, "bets[betId].closeTime < block.timestamp" );

        bets[betId].gameWinner = _winner;
    }
    
     function setCloseTime(uint256 betId,uint256 _closeTime) public onlyOwner{
       
       require(betId > 0 && betId <= currentBet, "betId > 0 && betId <= currentBet" );
       require(bets[betId].gameWinner == 0, "bets[betId].gameWinner == 0" );

        bets[betId].closeTime = _closeTime;
    }
    
    

         // fetches and sorts the reserves for a pair
    function getBets(uint8 _from,uint8 _to) public view returns (uint16[] memory gameWinner , uint256[] memory totalbets,  uint256[] memory totalBetsOne, uint256[] memory totalBetsTwo, uint256[] memory closeTime , uint16[] memory selected ) {
        uint8 size = _to - _from + 1;
        gameWinner = new uint16[](size);
        totalbets = new uint256[](size);
        totalBetsOne = new uint256[](size); 
        totalBetsTwo = new uint256[](size);
        closeTime = new uint256[](size);
       selected = new uint16[](size);
        uint8 i = 0;
        for(_from; _from <=_to ; _from++){
           (gameWinner[i],totalbets[i],totalBetsOne[i],totalBetsTwo[i],closeTime[i],selected[i]) = getBet(_from);
           i++;
        }
    }
     
      
    function getBet(uint256 betId) public view returns (uint16 gameWinner , uint256 totalbets,  uint256 totalBetsOne, uint256 totalBetsTwo, uint256 closeTime, uint16 selected){
       return (bets[betId].gameWinner,bets[betId].totalbets,bets[betId].totalBetsOne,bets[betId].totalBetsTwo,bets[betId].closeTime , bets[betId].playerInfo[msg.sender].selected );
    }

}