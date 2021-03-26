/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

// Sources flattened with hardhat v2.1.2 https://hardhat.org

// File contracts/ERC20/IERC20.sol


pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}


// File contracts/interfaces/IRERC20.sol

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title RERC20 contract interface, implements {IERC20}. See {RERC20}.
 * @author crypto-pumpkin
 */
interface IRERC20 is IERC20 {
    /// @notice access restriction - owner (R)
    function mint(address _account, uint256 _amount) external returns (bool);
    function burnByRuler(address _account, uint256 _amount) external returns (bool);
}


// File contracts/router.sol

pragma solidity ^0.8.0;

interface IRulerCore{

    struct Pair {
        bool active;
        uint48 expiry;
        address pairedToken;
        IRERC20 rcToken; // ruler capitol token, e.g. RC_Dai_wBTC_2_2021
        IRERC20 rrToken; // ruler repayment token, e.g. RR_Dai_wBTC_2_2021
        uint256 mintRatio; // 1e18, price of collateral / collateralization ratio
        uint256 feeRate; // 1e18
        uint256 colTotal;
    }

    function getPairList(address _col) external view returns (Pair[] memory);
    function deposit(
        address _col,
        address _paired,
        uint48 _expiry,
        uint256 _mintRatio,
        uint256 _colAmt
    ) external;

}

contract Router{
    IRulerCore rulerCore;

    constructor(address _rulerCore){
        rulerCore = IRulerCore(_rulerCore);
    }

    function getPairInfo(address _col) external view returns(uint256){
        return rulerCore.getPairList(_col)[0].mintRatio;
    }

    function refinanceLoan(
        address _col,
        address _paired,
        uint256 _colAmt
    ) external {
        //Check if collateral supported.
        // require rulerCore.getPairList(_col) length > 0
        uint48 _expiry = rulerCore.getPairList(_col)[0].expiry;
        uint256 _mintRatio = rulerCore.getPairList(_col)[0].mintRatio;
        rulerCore.deposit(_col, _paired, _expiry, _mintRatio, _colAmt);
    }
}


// File contracts/routerFlat.sol