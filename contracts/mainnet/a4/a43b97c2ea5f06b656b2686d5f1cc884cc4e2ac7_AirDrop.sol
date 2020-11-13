pragma solidity ^0.5.2;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract COwnable {
    address private __owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        __owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_isOwner());
        _;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return __owner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner() {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
     /*
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(__owner, address(0));
        __owner = address(0);
    }
    */
    

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function _isOwner() internal view returns (bool) {
        return msg.sender == __owner;
    }

    

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(__owner, newOwner);
        __owner = newOwner;
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title AirDrop
 * @dev Airdrop program. https://github.com/0x20bf/0xBlock
 */

contract AirDrop is COwnable {
    mapping (address => uint256) public whitelist;
    address public token_address;
    uint256 private _decimals;

    constructor(address token, uint256 decimals) public{ 
        token_address = token;
        _decimals = decimals;
    }

    function redeem() public returns(bool res) {
        require (whitelist[msg.sender] > 0 );
        IERC20 token = IERC20(token_address);
        token.transfer(msg.sender, whitelist[msg.sender]);
        whitelist[msg.sender] = 0;
        return true;
    }

    function setWhitelist(address[] memory accounts, uint256[] memory amounts) public onlyOwner() returns(bool res) {
        require (accounts.length == amounts.length);
        for(uint256 i=0; i<accounts.length; i++){
            if (accounts[i]!=address(0)){
                whitelist[accounts[i]] = amounts[i]*(10**_decimals);
            }
        }
        return true;
    }
    
    function withdraw(address token_addr) public onlyOwner() returns(bool res) {
        IERC20 token = IERC20(token_addr);
        token.transfer(msg.sender, token.balanceOf(address(this)));
        return true;
    }
    
    function kill() public onlyOwner() {
        address payable addr = address(uint160(owner()));
        selfdestruct(addr);
    }

}