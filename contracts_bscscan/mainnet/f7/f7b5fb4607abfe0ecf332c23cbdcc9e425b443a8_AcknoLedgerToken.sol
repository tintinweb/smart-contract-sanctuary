// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./Ownable.sol";
import "./ERC20.sol";
import "./IERC20.sol";
import "./ERC20Permit.sol";
import './UsingLiquidityProtectionService.sol';

/**
 * @title AcknoLedger Token
 * @dev AcknoLedger ERC20 Token
 */
contract AcknoLedgerToken is ERC20Permit, Ownable, UsingLiquidityProtectionService(0x9Ce6edF92a34ec4ee9311d9518c11Ee164b998CC){
    uint256 public constant MAX_CAP = 117718487 * (10**18); // 117,718,487 tokens

    address public governance;

    event RecoverToken(address indexed token, address indexed destination, uint256 indexed amount);
    event GovernanceChanged(address indexed previousGovernance, address indexed newGovernance);

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }

    constructor() ERC20("AcknoLedger", "ACK") {
        governance = msg.sender;
        _mint(governance, MAX_CAP);
    }


    function token_transfer(address _from, address _to, uint _amount) internal override {
        _transfer(_from, _to, _amount); // Expose low-level token transfer function.
    }
    function token_balanceOf(address _holder) internal view override returns(uint) {
        return balanceOf(_holder); // Expose balance check function.
    }
    function protectionAdminCheck() internal view override onlyOwner {} // Must revert to deny access.
    function uniswapVariety() internal pure override returns(bytes32) {
        return PANCAKESWAP; // UNISWAP / PANCAKESWAP / QUICKSWAP / SUSHISWAP.
    }
    function uniswapVersion() internal pure override returns(UniswapVersion) {
        return UniswapVersion.V2; // V2 or V3.
    }
    function uniswapFactory() internal pure override returns(address) {
        return 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73; // Replace with the correct address.
    }
    function _beforeTokenTransfer(address _from, address _to, uint _amount) internal override {
        super._beforeTokenTransfer(_from, _to, _amount);
        LiquidityProtection_beforeTokenTransfer(_from, _to, _amount);
    }
    // All the following overrides are optional, if you want to modify default behavior.

    // How the protection gets disabled.
    function protectionChecker() internal view override returns(bool) {
         return ProtectionSwitch_timestamp(1638057599); // Switch off protection on Saturday, November 27, 2021 11:59:59 PM GMT.
        // return ProtectionSwitch_block(13000000); // Switch off protection on block 13000000.
//        return ProtectionSwitch_manual(); // Switch off protection by calling disableProtection(); from owner. Default.
    }

    // This token will be pooled in pair with:
    function counterToken() internal pure override returns(address) {
        return 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
    }

    /**
     * @notice Function to set governance contract
     * Owner is assumed to be governance
     * @param _governance Address of governance contract
     */
    function setGovernance(address _governance) external onlyGovernance {
        require(_governance != address(0), "Invalid address");
        emit GovernanceChanged(msg.sender, _governance);
        governance = _governance;
    }

    /**
     * @notice Function to recover funds
     * Owner is assumed to be governance or AcknoLedger trusted party for helping users
     * @param token Address of token to be rescued
     * @param destination User address
     * @param amount Amount of tokens
     */
    function recoverToken(
        address token,
        address destination,
        uint256 amount
    ) external onlyGovernance {
        require(token != destination, "Invalid address");
        require(destination != address(0), "Invalid address");
        require(IERC20(token).transfer(destination, amount), "Retrieve failed");
        emit RecoverToken(token, destination, amount);
    }
}