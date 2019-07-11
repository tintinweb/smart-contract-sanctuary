/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.4;

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

interface Erc20Interface {
    function transfer(address _to, uint256 _value) external returns(bool);
    function symbol() external view returns(string memory);
    function name() external view returns(string memory);
    function decimals() external view returns(uint8);
    function balanceOf(address _owner) external view returns (uint256);
}

contract Airdrop is Ownable {
    using SafeMath for uint256;

    event RefundErc20(address indexed _tokenContract, address indexed _recipient, uint256 _amount);
    event RefundEth(address indexed _recipient, uint256 _amount);
    event AirdropErc20(address indexed _tokenContract, address[] _toAddresses, uint256[] _amounts);

    modifier checkAirdropData(address _tokenContract, address[] memory _toAddresses, uint256[] memory _amounts) {
        require(_toAddresses.length == _amounts.length);

        uint256 _tokenBalance = getTokenBalanceInContract(_tokenContract);
        uint256 _airdropTotalAmount;
        for (uint256 i; i < _amounts.length; i++) {
            require(_toAddresses[i] != address(0), "airdrop token to address(0) is not allowed.");
            _airdropTotalAmount = _airdropTotalAmount.add(_amounts[i]);
        }
        require(_tokenBalance >= _airdropTotalAmount, "token balance in this contract not enough.");
        _;
    }

    /**
    * @dev get token balance in this contract
    */
    function getTokenBalanceInContract(address _tokenContract) public view returns(uint256) {
        Erc20Interface _erc20Token = Erc20Interface(_tokenContract);
        return _erc20Token.balanceOf(address(this));
    }

    function airdrop(address _tokenContract, address[] memory _toAddresses, uint256[] memory _amounts)
        public
        onlyOwner
        checkAirdropData(_tokenContract, _toAddresses, _amounts)
    {
        Erc20Interface _erc20Token = Erc20Interface(_tokenContract);

        for (uint256 i; i < _toAddresses.length; i++) {
            if (_amounts[i] > 0) {
                _erc20Token.transfer(_toAddresses[i], _amounts[i]);
            }
        }

        emit AirdropErc20(_tokenContract, _toAddresses, _amounts);
    }

    /**
    * @dev transfer erc20 token back to _recipient from this contract
    */
    function refundErc20(address _tokenContract, address _recipient) public onlyOwner {
        uint256 _tokenBalance = getTokenBalanceInContract(_tokenContract);
        if (_tokenBalance > 0) {
            Erc20Interface _erc20Token = Erc20Interface(_tokenContract);
            _erc20Token.transfer(_recipient, _tokenBalance);
            emit RefundErc20(_tokenContract, _recipient, _tokenBalance);
        }
    }

    /**
    * @dev transfer eth back to _recipient from this contract
    */
    function refundEth(address payable _recipient) public onlyOwner {
        uint256 _ethBalance = address(this).balance;
        if (_ethBalance > 0) {
            _recipient.transfer(_ethBalance);
            emit RefundEth(_recipient, _ethBalance);
        }
    }

    function () external payable {
        //only receive ether, prevent invalid calls.
        require(msg.data.length == 0);
    }
}