// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ILendingPool {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
    * @dev Emitted on deposit()
    * @param reserve The address of the underlying asset of the reserve
    * @param user The address initiating the deposit
    * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
    * @param amount The amount deposited
    * @param referral The referral code used
    **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

}

interface ICamToken is IERC20 {
    function enter(uint256 _amount) external;
}

interface IQiVault is IERC20 {
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function depositCollateral(uint256 vaultID, uint256 amount) external;
    function createVault() external returns (uint256);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract CamZapper {
    using SafeMath for uint256;
    ILendingPool aavePolyPool = ILendingPool(0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf);
    IERC20 asset;
    IERC20 amToken;
    ICamToken camToken;
    IQiVault camTokenVault;

    constructor(address _asset, address _amAsset, address _camAsset, address _camAssetVault) public {
        asset = IERC20(_asset);
        amToken = IERC20(_amAsset);
        camToken = ICamToken(_camAsset);
        camTokenVault = IQiVault(_camAssetVault);
    }

    function camZap(uint256 amount) public returns (uint256){

        require(amount > 0, "You need to deposit at least some tokens");

        uint256 allowance = asset.allowance(msg.sender, address(this));
        asset.transferFrom(msg.sender, address(this), amount);
        require(allowance >= amount, "Check the token allowance");

        asset.approve(address(aavePolyPool), amount);
        aavePolyPool.deposit(address(asset), amount, address(this), 0);

        amToken.approve(address(camToken), amount);
        camToken.enter(amount);

        uint256 camTokenBal = camToken.balanceOf(address(this));

        try camTokenVault.tokenOfOwnerByIndex(msg.sender, 0) returns(uint256 vaultId){
            camToken.approve(address(camTokenVault), camTokenBal);
            camTokenVault.depositCollateral(vaultId, camTokenBal);
        } catch Error(string memory reason){
            uint256 vaultId = camTokenVault.createVault();
            camToken.approve(address(camTokenVault), camTokenBal);
            camTokenVault.depositCollateral(vaultId, camTokenBal);
            camTokenVault.safeTransferFrom(address(this), (msg.sender), vaultId);
        }
        return camToken.balanceOf(msg.sender);
    }
}

contract WEthZapper is CamZapper(
0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619, //Weth
0x28424507fefb6f7f8E9D3860F56504E4e5f5f390, //amWeth
0x0470CD31C8FcC42671465880BA81D631F0B76C1D, //camWeth
0x11A33631a5B5349AF3F165d2B7901A4d67e561ad  //camWethVault
){}

contract AaveZapper is CamZapper(
0xD6DF932A45C0f255f85145f286eA0b292B21C90B, //Aave
0x1d2a0E5EC8E5bBDCA5CB219e649B565d8e5c3360, //amAave
0xeA4040B21cb68afb94889cB60834b13427CFc4EB, //camAave
0x578375c3af7d61586c2C3A7BA87d2eEd640EFA40  //camAaveVault
){}

contract WMaticZapper is CamZapper(
0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270, //WMATIC
0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4, //amWMATIC
0x7068Ea5255cb05931EFa8026Bd04b18F3DeB8b0B, //camWMATIC
0x88d84a85A87ED12B8f098e8953B322fF789fCD1a  //camWMATCVault
){}

