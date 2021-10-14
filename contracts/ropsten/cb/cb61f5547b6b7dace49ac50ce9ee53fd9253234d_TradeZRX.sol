/**
 *Submitted for verification at Etherscan.io on 2021-10-14
*/

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
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

pragma solidity ^0.5.0;

contract TradeZRX {

    address payable OWNER;

    // ZRX Config ROPSTEN
    address ZRX_EXCHANGE_ADDRESS = 0xFb2DD2A1366dE37f7241C83d47DA58fd503E2C64;
    address ZRX_ERC20_PROXY_ADDRESS = 0xB1408f4c245a23c31b98D2C626777D4c0d766caA;
    address ZRX_STAKING_PROXY = 0xfAabCEe42Ab6B9c649794ac6c133711071897EE9; // Fee collector

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == OWNER, "caller is not the owner!");
        _;
    }

    function zrxTrade(address _from, uint256 _amount, bytes memory _calldataHexString) onlyOwner public payable {
        _zrxTrade(_from, _amount, _calldataHexString);
    }

    function _zrxTrade(address _from, uint256 _amount, bytes memory _calldataHexString) internal {
        // Approve tokens
        IERC20 _fromIERC20 = IERC20(_from);
        _fromIERC20.approve(ZRX_ERC20_PROXY_ADDRESS, _amount);

        // Swap tokens
        address(ZRX_EXCHANGE_ADDRESS).call.value(msg.value)(_calldataHexString);

        // Reset approval
        _fromIERC20.approve(ZRX_ERC20_PROXY_ADDRESS, 0);
    }
    
}