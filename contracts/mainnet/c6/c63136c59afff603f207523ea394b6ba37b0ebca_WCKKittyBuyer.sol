/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

pragma solidity ^0.5.10;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
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
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract WCKKittyBuyer is Ownable {

    // OpenZeppelin&#39;s SafeMath library is used for all arithmetic operations to avoid overflows/underflows.
    using SafeMath for uint256;

    /* ********** */
    /* DATA TYPES */
    /* ********** */

    /* ****** */
    /* EVENTS */
    /* ****** */

    event KittyBoughtWithWCK(uint256 kittyId, uint256 wckSpent);
    event DevFeeUpdated(uint256 newDevFee);

    /* ******* */
    /* STORAGE */
    /* ******* */

    /* ********* */
    /* CONSTANTS */
    /* ********* */

    address kittyCoreAddress = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
    address kittySalesAddress = 0xb1690C08E213a35Ed9bAb7B318DE14420FB57d8C;
    address wrappedKittiesAddress = 0x09fE5f0236F0Ea5D930197DCE254d77B04128075;
    address uniswapExchangeAddress = 0x4FF7Fa493559c40aBd6D157a0bfC35Df68d8D0aC;

    uint256 devFeeInBasisPoints = 375;

    /* ********* */
    /* FUNCTIONS */
    /* ********* */

    function buyKittyWithWCK(uint256 _kittyId, uint256 _maxWCKWeiToSpend) external {
        ERC20(wrappedKittiesAddress).transferFrom(msg.sender, address(this), _maxWCKWeiToSpend);
        uint256 costInWei = KittySales(kittySalesAddress).getCurrentPrice(_kittyId);
        uint256 tokensSold = UniswapExchange(uniswapExchangeAddress).tokenToEthSwapOutput(_computePriceWithDevFee(costInWei), _maxWCKWeiToSpend, ~uint256(0));
        KittyCore(kittySalesAddress).bid.value(costInWei)(_kittyId);
        ERC20(wrappedKittiesAddress).transfer(msg.sender, _maxWCKWeiToSpend.sub(tokensSold));
        KittyCore(kittyCoreAddress).transfer(msg.sender, _kittyId);
        emit KittyBoughtWithWCK(_kittyId, tokensSold);
    }

    function transferERC20(address _erc20Address, address _to, uint256 _value) external onlyOwner {
        ERC20(_erc20Address).transfer(_to, _value);
    }

    function withdrawOwnerEarnings() external onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function updateFee(uint256 _newFee) external onlyOwner {
        devFeeInBasisPoints = _newFee;
        emit DevFeeUpdated(_newFee);
    }

    constructor() public {
        ERC20(wrappedKittiesAddress).approve(uniswapExchangeAddress, ~uint256(0));
    }

    function() external payable {}

    function _computePriceWithDevFee(uint256 _costInWei) internal view returns (uint256) {
        return (_costInWei.mul(uint256(10000).add(devFeeInBasisPoints))).div(uint256(10000));
    }
}

contract KittyCore {
    function transfer(address _to, uint256 _tokenId) external;
    function bid(uint256 _tokenId) external payable;
}

contract KittySales {
    function getCurrentPrice(uint256 _tokenId) external view returns (uint256);
}

contract ERC20 {
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
}

contract UniswapExchange {
    function tokenToEthSwapOutput(uint256 eth_bought, uint256 max_tokens, uint256 deadline) external returns (uint256  tokens_sold);
}