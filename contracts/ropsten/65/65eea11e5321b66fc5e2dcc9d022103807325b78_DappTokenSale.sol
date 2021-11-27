pragma solidity ^0.5.16;

import "./DappToken.sol";

contract DappTokenSale {
    address payable owner;
    DappToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    /**
     * @param _buyer Buyer's address.
     * @param _amount Amount of token.
     */
    event Sell(address indexed _buyer, uint256 _amount);

    /**
     * @param _tokenContract Token contract address.
     * @param _tokenPrice Initial token price.
     */
    constructor(DappToken _tokenContract, uint256 _tokenPrice) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        /**
         * Gas optimization: this is cheaper than requiring 'a' not being zero,
         * but the benefit is lost if 'b' is also tested.
         * See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
         */
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @param _numberOfTokens Token amount.
     */
    function buyTokens(uint256 _numberOfTokens) public payable {
        require(msg.value == mul(_numberOfTokens, tokenPrice));
        require(tokenContract.balanceOf(address(this)) >= _numberOfTokens);
        require(tokenContract.transfer(msg.sender, _numberOfTokens));
        tokensSold += _numberOfTokens;
        emit Sell(msg.sender, _numberOfTokens);
    }

    /**
     * @dev Ends sale the token sale period.
     */
    function endSale() public onlyOwner {
        uint256 contractBalance = tokenContract.balanceOf(address(this));
        if (contractBalance > 0) require(tokenContract.transfer(owner, contractBalance));
        selfdestruct(owner);
    }
}