/**
 *Submitted for verification at Etherscan.io on 2021-07-08
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
    address public RUNE;

    struct Coin {
        address asset;
        uint amount;
    }

    // Vault allowance for each asset
    mapping(address => mapping(address => uint)) public vaultAllowance;
    // Reserve for each asset
    mapping(address => uint) public reserve;

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    // Emitted for all deposits, the memo distinguishes for swap, add, remove, donate etc
    event Deposit(address indexed to, address indexed asset, uint amount, string memo);

    // Emitted for all outgoing transfers, the vault dictates who sent it, memo used to track.
    event TransferOut(address indexed vault, address indexed to, address asset, uint amount, string memo);

    // Changes the spend allowance between vaults
    event TransferAllowance(address indexed oldVault, address indexed newVault, address asset, uint amount, string memo);

    // Specifically used to batch send the entire vault assets
    event VaultTransfer(address indexed oldVault, address indexed newVault, Coin[] coins, string memo);

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    constructor(address rune) {
        RUNE = rune;
        _status = _NOT_ENTERED;
    }

    // Backwards compatible
    function deposit(address payable vault, address asset, uint amount, string memory memo) external payable {
        _deposit(vault, asset, amount, memo);
    }

    // Deposit with Expiry (preferred)
    function depositWithExpiry(address payable vault, address asset, uint amount, string memory memo, uint expiration) external payable {
        require(block.timestamp < expiration, "THORChain_Router: expired");
        _deposit(vault, asset, amount, memo);
    }

    // Deposit an asset with a memo. ETH is forwarded, ERC-20 stays in ROUTER
    function _deposit(address payable vault, address asset, uint amount, string memory memo) internal nonReentrant{
        uint safeAmount;
        if(asset == address(0)){
            safeAmount = msg.value;
            (bool success, bytes memory data) = vault.call{value:safeAmount}("");
            require(success && (data.length == 0 || abi.decode(data, (bool))));
        } else if(asset == RUNE) {
            safeAmount = amount;
            iRUNE(RUNE).transferTo(address(this), amount);
            iERC20(RUNE).burn(amount);
        } else {
            safeAmount = safeTransferFrom(asset, amount); // Transfer asset
            reserve[asset] += safeAmount; // Add to reserve
            vaultAllowance[vault][asset] += safeAmount; // Credit to chosen vault
        }
        emit Deposit(vault, asset, safeAmount, memo);
    }

    //############################## ALLOWANCE TRANSFERS ##############################

    // Use for "moving" assets between vaults (asgard<>ygg), as well "churning" to a new Asgard
    function transferAllowance(address router, address newVault, address asset, uint amount, string memory memo) external {
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
        _transferOut(to, asset, amount, memo);
    }

    // Backwards compatible
    function _transferOut(address payable to, address asset, uint amount, string memory memo) internal nonReentrant {
        uint safeAmount; bool success; bytes memory data;
        if(asset == address(0)){
            safeAmount = msg.value;
            (success, data) = to.call{value:msg.value}(""); // Send ETH
        } else {
            vaultAllowance[msg.sender][asset] -= amount; // Reduce allowance
            reserve[asset] -= amount;
            (success, data) = asset.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
            safeAmount = amount;
        }
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        emit TransferOut(msg.sender, to, asset, safeAmount, memo);
    }

    // Batch Transfer
    function batchTransferOut(address[] memory recipients, Coin[] memory coins, string[] memory memos) external payable {
        for(uint i = 0; i < coins.length; i++){
            transferOut(payable(recipients[i]), coins[i].asset, coins[i].amount, memos[i]);
        }
    }

    //############################## VAULT MANAGEMENT ##############################

    // A vault can call to "return" all assets to an asgard, including ETH. 
    function returnVaultAssets(address router, address payable asgard, Coin[] memory coins, string memory memo) external payable {
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
        (bool success, bytes memory data) = asgard.call{value:msg.value}(""); //ETH amount needs to be parsed from tx.
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    //############################## HELPERS ##############################

    // Safe transferFrom in case asset charges transfer fees
    function safeTransferFrom(address _asset, uint _amount) internal returns(uint amount) {
        (bool success, bytes memory data) = _asset.call(abi.encodeWithSelector(0x23b872dd, msg.sender, address(this), _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
        return (iERC20(_asset).balanceOf(address(this)) - reserve[_asset]);
    }

    // Decrements and Increments Allowances between two vaults
    function _adjustAllowances(address _newVault, address _asset, uint _amount) internal {
        vaultAllowance[msg.sender][_asset] -= _amount;
        vaultAllowance[_newVault][_asset] += _amount;
    }

    // Adjust allowance and forwards funds to new router, credits allowance to desired vault
    function _routerDeposit(address _router, address _vault, address _asset, uint _amount, string memory _memo) internal {
        vaultAllowance[msg.sender][_asset] -= _amount;
        reserve[_asset] -= _amount;
        require(iERC20(_asset).approve(_router, _amount)); // Approve to transfer
        iROUTER(_router).deposit(_vault, _asset, _amount, _memo); // Transfer by depositing
    }
}