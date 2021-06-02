/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/lender/operator.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.15 >=0.6.12;

////// lib/tinlake-auth/src/auth.sol
// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
/* pragma solidity >=0.5.15; */

contract Auth {
    mapping (address => uint256) public wards;
    
    event Rely(address indexed usr);
    event Deny(address indexed usr);

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "not-authorized");
        _;
    }

}

////// src/lender/operator.sol
/* pragma solidity >=0.6.12; */

/* import "tinlake-auth/auth.sol"; */

interface TrancheLike_4 {
    function supplyOrder(address usr, uint currencyAmount) external;
    function redeemOrder(address usr, uint tokenAmount) external;
    function disburse(address usr) external returns (uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken);
    function disburse(address usr, uint endEpoch) external returns (uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken);
    function currency() external view returns (address);
}

interface RestrictedTokenLike {
    function hasMember(address) external view returns (bool);
}

interface EIP2612PermitLike {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

interface DaiPermitLike {
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

contract Operator is Auth {
    TrancheLike_4 public tranche;
    RestrictedTokenLike public token;

    // Events
    event SupplyOrder(uint indexed amount);
    event RedeemOrder(uint indexed amount);

    constructor(address tranche_) {
        wards[msg.sender] = 1;
        tranche = TrancheLike_4(tranche_);
    }

    // sets the dependency to another contract
    function depend(bytes32 contractName, address addr) public auth {
        if (contractName == "tranche") { tranche = TrancheLike_4(addr); }
        else if (contractName == "token") { token = RestrictedTokenLike(addr); }
        else revert();
    }

    // only investors that are on the memberlist can submit supplyOrders
    function supplyOrder(uint amount) public {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        tranche.supplyOrder(msg.sender, amount);
        emit SupplyOrder(amount);
    }

    // only investors that are on the memberlist can submit redeemOrders
    function redeemOrder(uint amount) public {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        tranche.redeemOrder(msg.sender, amount);
        emit RedeemOrder(amount);
    }

    // only investors that are on the memberlist can disburse
    function disburse() external
        returns(uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken)
    {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        return tranche.disburse(msg.sender);
    }

    function disburse(uint endEpoch) external
        returns(uint payoutCurrencyAmount, uint payoutTokenAmount, uint remainingSupplyCurrency,  uint remainingRedeemToken)
    {
        require((token.hasMember(msg.sender) == true), "user-not-allowed-to-hold-token");
        return tranche.disburse(msg.sender, endEpoch);
    }

    // --- Permit Support ---
    function supplyOrderWithDaiPermit(uint amount, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        DaiPermitLike(tranche.currency()).permit(msg.sender, address(tranche), nonce, expiry, true, v, r, s);
        supplyOrder(amount);
    }
    function supplyOrderWithPermit(uint amount, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        EIP2612PermitLike(tranche.currency()).permit(msg.sender, address(tranche), value, deadline, v, r, s);
        supplyOrder(amount);
    }
    function redeemOrderWithPermit(uint amount, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) public {
        EIP2612PermitLike(address(token)).permit(msg.sender, address(tranche), value, deadline, v, r, s);
        redeemOrder(amount);
    }
}