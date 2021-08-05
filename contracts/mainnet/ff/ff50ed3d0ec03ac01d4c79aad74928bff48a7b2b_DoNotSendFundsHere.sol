/**
 *Submitted for verification at Etherscan.io on 2020-07-23
*/

pragma solidity >=0.4.22 <0.7.0;

/**
 ******************************************************************
 *
 *                    ██████████████████
 *                  ██                  ██
 *                ██  ██████████████████  ██
 *              ██  ██████████████████████  ██
 *            ██  ██████████████████████████  ██
 *          ██  ██████████████████████████████  ██
 *        ██  ██████████████████████████████████  ██
 *      ██  ██████████████████████████████████████  ██
 *      ██  ██████    ██      ████  ████    ██████  ██
 *      ██  ████  ████████  ████  ██  ██  ██  ████  ██
 *      ██  ████  ████████  ████  ██  ██  ██  ████  ██
 *      ██  ██████  ██████  ████  ██  ██    ██████  ██
 *      ██  ████████  ████  ████  ██  ██  ████████  ██
 *      ██  ████████  ████  ████  ██  ██  ████████  ██
 *      ██  ████    ██████  ██████  ████  ████████  ██
 *      ██  ██████████████████████████████████████  ██
 *        ██  ██████████████████████████████████  ██
 *          ██  ██████████████████████████████  ██
 *            ██  ██████████████████████████  ██
 *              ██  ██████████████████████  ██
 *                ██  ██████████████████  ██
 *                  ██                  ██
 *                    ██████████████████
 *
 ******************************************************************
 *                   DO NOT SEND ETH HERE!
 ****************************************************************** 
 */ 

/**
 * @title DoNotSendFundsHere
 * @dev This contract is a stub to recover mainnet funds sent to the Prysmatic Labs testnet address. 
 * The testnet contract is deployed on Goerli, not on Ethereum's main network. Do not send funds here!
 * If you sent funds here by mistake, please email contact at prysmaticlabs.com with 
 * proof that you are the originator of the lost funds.
 */
contract DoNotSendFundsHere {
    address payable public owner;

    /// @dev Initialize the contract with the contract creator as the owner.
    constructor() public {
        owner = msg.sender;
    }
    
    /// @dev Modifier to require the message sender to be the owner.
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Sender not authorized."
        );
        _;
    }
    
    /// @dev Change the sole owner of the contract.
    /// @param _newOwner the address of the new owner of this contract.
    function changeOwner(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    /// @dev Send all ETH held by the contract to the contract owner.
    function recoverETHFunds() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    /// @dev Approve ERC20 spending for a particular ERC20 token.
    /// @param _token The ERC20 token address.
    /// @param _spender The spender address to authorize spending on behalf of this contract.
    /// @param _value The amount authorized for the _spender.
    function approveERC20Funds(ERC20 _token, address _spender, uint _value) public onlyOwner {
        _token.approve(_spender, _value);
    }
    
    /// @dev Send all of the ERC20 token owned by this contract to the contract owner.
    /// @param _token The ERC20 token address.
    function recoverERC20Funds(ERC20 _token) public onlyOwner {
        _token.transfer(owner, _token.balanceOf(address(this)));
    }
    
    /// @dev Fallback payable. DO NOT SEND ETH HERE!!! The reason this does not reject any non-zero transaction
    /// is that users sending directly from centralized exchanges may experience a total loss if their transaction
    /// is rejected. Do not send ETH here.
    receive() external payable { }
}

interface ERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}