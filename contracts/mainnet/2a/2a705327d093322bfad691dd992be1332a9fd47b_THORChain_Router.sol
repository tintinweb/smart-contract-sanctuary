/**
 *Submitted for verification at Etherscan.io on 2021-04-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

// ERC20 Interface
interface iERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint) external returns (bool);
    function burn(uint) external;
}
// RUNE Interface
interface iRUNE {
    function transferTo(address, uint) external returns (bool);
}
// ROUTER Interface
interface iROUTER {
    function deposit(address, address, uint, string calldata) external;
}

// THORChain_Router is managed by THORChain Vaults
contract THORChain_Router {
    address public RUNE = 0x3155BA85D5F96b2d030a4966AF206230e46849cb; //mainnet

    struct Coin {
        address asset;
        uint amount;
    }

    // Vault allowance for each asset
    mapping(address => mapping(address => uint)) public vaultAllowance;

    // Emitted for all deposits, the memo distinguishes for swap, add, remove, donate etc
    event Deposit(address indexed to, address indexed asset, uint amount, string memo);

    // Emitted for all outgoing transfers, the vault dictates who sent it, memo used to track.
    event TransferOut(address indexed vault, address indexed to, address asset, uint amount, string memo);

    // Changes the spend allowance between vaults
    event TransferAllowance(address indexed oldVault, address indexed newVault, address asset, uint amount, string memo);

    // Specifically used to batch send the entire vault assets
    event VaultTransfer(address indexed oldVault, address indexed newVault, Coin[] coins, string memo);

    constructor() {}

    // Deposit an asset with a memo. ETH is forwarded, ERC-20 stays in ROUTER
    function deposit(address payable vault, address asset, uint amount, string memory memo) public payable {
        uint safeAmount;
        if(asset == address(0)){
            safeAmount = msg.value;
            vault.call{value:safeAmount}("");
        } else if(asset == RUNE) {
            safeAmount = amount;
            iRUNE(RUNE).transferTo(address(this), amount);
            iERC20(RUNE).burn(amount);
        } else {
            safeAmount = safeTransferFrom(asset, amount); // Transfer asset
            vaultAllowance[vault][asset] += safeAmount; // Credit to chosen vault
        }
        emit Deposit(vault, asset, safeAmount, memo);
    }

    //############################## ALLOWANCE TRANSFERS ##############################

    // Use for "moving" assets between vaults (asgard<>ygg), as well "churning" to a new Asgard
    function transferAllowance(address router ,address newVault, address asset, uint amount, string memory memo) public {
        if (router == address(this)){
            _adjustAllowances(newVault, asset, amount);
            emit TransferAllowance(msg.sender, newVault, asset, amount, memo);
        } else {
            _routerDeposit(router, newVault, asset, amount, memo);
        }
    }

    //############################## ASSET TRANSFERS ##############################

    // Any vault calls to transfer any asset to any recipient.
    function transferOut(address payable to, address asset, uint amount, string memory memo) public payable {
        uint safeAmount;
        if(asset == address(0)){
            safeAmount = msg.value;
            to.call{value:msg.value}(""); // Send ETH
        } else {
            vaultAllowance[msg.sender][asset] -= amount; // Reduce allowance
            asset.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
            safeAmount = amount;
        }
        emit TransferOut(msg.sender, to, asset, safeAmount, memo);
    }

    // Batch Transfer
    function batchTransferOut(address[] memory recipients, Coin[] memory coins, string[] memory memos) public payable {
        for(uint i = 0; i < coins.length; i++){
            transferOut(payable(recipients[i]), coins[i].asset, coins[i].amount, memos[i]);
        }
    }

    //############################## VAULT MANAGEMENT ##############################

    // A vault can call to "return" all assets to an asgard, including ETH. 
    function returnVaultAssets(address router, address payable asgard, Coin[] memory coins, string memory memo) public payable {
        if (router == address(this)){
            for(uint i = 0; i < coins.length; i++){
                _adjustAllowances(asgard, coins[i].asset, coins[i].amount);
            }
            emit VaultTransfer(msg.sender, asgard, coins, memo); // Does not include ETH.           
        } else {
            for(uint i = 0; i < coins.length; i++){
                _routerDeposit(router, asgard, coins[i].asset, coins[i].amount, memo);
            }
        }
        asgard.call{value:msg.value}(""); //ETH amount needs to be parsed from tx.
    }

    //############################## HELPERS ##############################

    // Safe transferFrom in case asset charges transfer fees
    function safeTransferFrom(address _asset, uint _amount) internal returns(uint amount) {
        uint _startBal = iERC20(_asset).balanceOf(address(this));
        (bool success, bytes memory data) = _asset.call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        return (iERC20(_asset).balanceOf(address(this)) - _startBal);
    }

    // Decrements and Increments Allowances between two vaults
    function _adjustAllowances(address _newVault, address _asset, uint _amount) internal {
        vaultAllowance[msg.sender][_asset] -= _amount;
        vaultAllowance[_newVault][_asset] += _amount;
    }

    // Adjust allowance and forwards funds to new router, credits allowance to desired vault
    function _routerDeposit(address _router, address _vault, address _asset, uint _amount, string memory _memo) internal {
        vaultAllowance[msg.sender][_asset] -= _amount;
        iERC20(_asset).approve(_router, _amount); // Approve to transfer
        iROUTER(_router).deposit(_vault, _asset, _amount, _memo); // Transfer
    }
}