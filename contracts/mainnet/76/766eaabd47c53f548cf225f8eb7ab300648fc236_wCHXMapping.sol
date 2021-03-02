/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

pragma solidity 0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract wCHXMapping is Ownable {
    event AddressMapped(address indexed ethAddress, string chxAddress, string signature);
    event AddressMappingRemoved(address indexed ethAddress, string chxAddress, string signature);

    mapping (address => string) private ethToChxAddresses;
    mapping (string => address) private chxToEthAddresses;
    mapping (string => string) private chxToSignatures;

    constructor()
        public
    {
    }

    function chxAddress(address _ethAddress)
        external
        view
        returns (string memory) 
    {
        return ethToChxAddresses[_ethAddress];
    }

    function ethAddress(string calldata _chxAddress)
        external
        view
        returns (address) 
    {
        return chxToEthAddresses[_chxAddress];
    }

    function signature(string calldata _chxAddress)
        external
        view
        returns (string memory) 
    {
        return chxToSignatures[_chxAddress];
    }

    function mapAddress(string calldata _chxAddress, string calldata _signature)
        external
    {
        address _ethAddress = _msgSender();

        require(bytes(ethToChxAddresses[_ethAddress]).length == 0);
        require(chxToEthAddresses[_chxAddress] == address(0));
        require(bytes(chxToSignatures[_chxAddress]).length == 0);
        checkChxAddress(_chxAddress);
        checkSignature(_signature);

        ethToChxAddresses[_ethAddress] = _chxAddress;
        chxToEthAddresses[_chxAddress] = _ethAddress;
        chxToSignatures[_chxAddress] = _signature;

        emit AddressMapped(_ethAddress, _chxAddress, _signature);
    }

    function removeMappedAddress(address _ethAddress)
        external
        onlyOwner
    {
        string memory _chxAddress = ethToChxAddresses[_ethAddress];
        require(bytes(_chxAddress).length != 0);

        string memory _signature = chxToSignatures[_chxAddress];
        require(bytes(_signature).length != 0);
        require(chxToEthAddresses[_chxAddress] == _ethAddress);
        
        delete ethToChxAddresses[_ethAddress];
        delete chxToEthAddresses[_chxAddress];
        delete chxToSignatures[_chxAddress];
        
        emit AddressMappingRemoved(_ethAddress, _chxAddress, _signature);
    }

    function isAlphanumericChar(bytes1 _char)
        private
        pure
        returns (bool)
    {
        return (_char >= 0x30 && _char <= 0x39) || 
            (_char >= 0x41 && _char <= 0x5A) || 
            (_char >= 0x61 && _char <= 0x7A);
    }

    function checkChxAddress(string memory _chxAddress)
        private 
        pure
    {
        bytes memory _strBytes = bytes(_chxAddress);
        bytes memory _prefix = bytes("CH");
        require(_strBytes[0] == _prefix[0] && _strBytes[1] == _prefix[1], "Invalid CHX address");

        bytes1 _lastChar = _strBytes[_strBytes.length - 1];
        require(isAlphanumericChar(_lastChar), "CHX address ends with incorrect character");
    }

    function checkSignature(string memory _signature)
        private 
        pure
    {
        bytes memory _strBytes = bytes(_signature);

        bytes1 _firstChar = _strBytes[0];
        require(isAlphanumericChar(_firstChar), "Signature ends with incorrect character");

        bytes1 _lastChar = _strBytes[_strBytes.length - 1];
        require(isAlphanumericChar(_lastChar), "Signature ends with incorrect character");
    }

    // Enable recovery of ether sent by mistake to this contract's address.
    function drainStrayEther(uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        payable(owner()).transfer(_amount);
        return true;
    }

    // Enable recovery of any ERC20 compatible token sent by mistake to this contract's address.
    function drainStrayTokens(IERC20 _token, uint _amount)
        external
        onlyOwner
        returns (bool)
    {
        return _token.transfer(owner(), _amount);
    }
}