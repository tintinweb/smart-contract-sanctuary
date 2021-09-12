/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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

/// @title Scratch & Win
/// @author FreezyEx (https://github.com/FreezyEx)
/// @notice A smart contract that allows to play scratch & win game.
contract ScratchAndWin is Context, Ownable {
    
    IERC20 token;
    
    uint256 public ticketPrice = 100000 * 10**9;  // 1 ticket = 100k tokens
    uint256[] public weights = [600, 250, 75, 50, 25];
    uint256[] public prizes = [50000, 150000, 300000, 500000, 1000000];

         ///////////////////////
        // Tracker Variables //
       ///////////////////////

    bool public isActive;
    uint256 public totTicketsBought;
    uint256 public numWinningTickets;

             ////////////
            // Events //
           ////////////

    event PrizesAndWeightsUpdated(uint256[] _prizes, uint256[] _weights);
    event TicketPriceUpdated(uint256 newPrice);
    event IsActiveUpdated(bool enabled);
    event TokenUpdated(address newToken);
    event TicketResult(uint256 result);

    constructor(IERC20 tokenAddress){
       token = tokenAddress;
    }

          ////////////////////
         // Core Functions //
        ////////////////////
        
    /// @notice Generate a random number between "from" and "to"
    /// @param from The lowest number of the interval
    /// @param to The biggest number of the interval
    /// @param salty A random number generated off-chain
    function getRandom(uint256 from, uint256 to, uint256 salty) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return (seed % (to - from) + from);
    }
    
    /// @notice Check if the contract has enough tokens to pay 
    ///     the highest rewards.
    ///     The msg.sender token balance must be >= ticketPrice.
    function prevalidatePurchase() internal view{
        require(isActive, "Not Active yet");
        require(token.balanceOf(msg.sender) >= ticketPrice, "Insufficient balance");
        require(token.balanceOf(address(this)) >= (prizes[prizes.length -1] * 10**9), "No sufficient balance in contract");
    }

    
    /// @param salty A random amount 
    /// @notice Takes the tokens from the user and calculate the prize
    /// @dev Use a script to pass the "salty" parameter.
    function buyTicket(uint256 salty) public returns(uint256){
        prevalidatePurchase();
        token.transferFrom(msg.sender, address(this), ticketPrice);
        totTicketsBought++;
        uint256 random = getRandom(0, 999, salty);
        for(uint256 i = 0; i < prizes.length; i++){
            if(random < weights[i]){
                if(prizes[i] != prizes[0]) numWinningTickets++;
                token.transfer(msg.sender, prizes[i] * 10**9);
                emit TicketResult(prizes[i]);
                return prizes[i];
            }
            random -= weights[i];
        }
        emit TicketResult(prizes[0]);
        return prizes[0];
    }

         //////////////////////
        // Update Functions //
       //////////////////////
    
    /// @notice Updates the weights[] and prizes[] arrays
    /// @dev "newPrizes[]" and "newWeights[]" must have same size
    function updatePrizesAndWeights(uint256[] memory newPrizes, uint256[] memory newWeights) external onlyOwner{
       require(newPrizes.length == newWeights.length, "Arrays must have same size");
       prizes = newPrizes;
       weights = newWeights;
       emit PrizesAndWeightsUpdated(newPrizes, newWeights);
    }
    
    /// @notice Updates the ticket price
    /// @dev Decimals are alredy added by the function
    function updateTicketPrice(uint256 newPrice) external onlyOwner{
       ticketPrice = newPrice * 10**9;
       emit TicketPriceUpdated(newPrice);
    }
    
    /// @notice Updates "isActive" flag
    /// @dev If _enabled = true ----> game is active
    ///     If _enabled = false ----> game not active
    function updateIsActive(bool _enabled) external onlyOwner{
       require(isActive != _enabled, "You can't set the same flag");
       isActive = _enabled;
       emit IsActiveUpdated(_enabled);
    }
    
    /// @notice Updates token address
    /// @dev Token address must be valid
    function updateToken(address newToken) external onlyOwner{
       require(newToken != address(0), "Dead address is not valid");
       token = IERC20(newToken);
       emit TokenUpdated(newToken);
    }
    
    /// @notice Withdraws tokens sent by mistake
    /// @dev "isActive" must be false to call this
    function rescueTokens(address tokenAddress, uint256 amount) external onlyOwner{
        require(!isActive, "Game is still active");
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

}