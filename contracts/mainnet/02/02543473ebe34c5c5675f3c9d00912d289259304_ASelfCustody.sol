/**
 *Submitted for verification at Etherscan.io on 2021-01-11
*/

/*

 Copyright 2019 RigoBlock, Gabriele Rigo.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

*/

// solhint-disable-next-line
pragma solidity =0.7.6;

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}


interface Token {

    function transfer(address _to, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
}

interface DragoEventful {

    function customDragoLog(bytes4 _methodHash, bytes calldata _encodedParams) external returns (bool success);
}

abstract contract Drago {

    address public owner;

    function getEventful() external view virtual returns (address);
}

/// @title Self Custody adapter - A helper contract for self custody.
/// @author Gabriele Rigo - <[email protected]>
// solhint-disable-next-line
contract ASelfCustody is SafeMath {
    
    // Mainnet GRG Address
    address constant private GRG_ADDRESS = address(0x4FbB350052Bca5417566f188eB2EBCE5b19BC964);

    // Ropsten GRG Address
    // address constant private GRG_ADDRESS = address(0x6FA8590920c5966713b1a86916f7b0419411e474);

    uint256 constant internal MIN_TOKEN_VALUE = 1e21;
    
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));

    /// @dev transfers ETH or tokens to self custody.
    /// @param selfCustodyAccount Address of the target account.
    /// @param token Address of the target token.
    /// @param amount Number of tokens.
    /// @return Bool the transaction was successful.
    /// @return Number of GRG pool operator shortfall.
    /// @notice Transfeer of tokens excluded from GRG requirement for now.
    function transferToSelfCustody(
        address payable selfCustodyAccount,
        address token,
        uint256 amount)
        external
        returns (bool, uint256)
    {
        require(
            Drago(
                address(this)
            ).owner() == msg.sender,
            "FAIL_OWNER_CHECK"
        );

        require(amount != uint256(0));

        (bool satisfied, uint256 shortfall) = _poolGRGminimumSatisfied(GRG_ADDRESS, token, amount);
        if (satisfied == true) {
            require(
                transferToSelfCustodyInternal(selfCustodyAccount, token, amount),
                "TRANSFER_FAIL_GRG_REQ_SATISFIED_ERROR"
                );
            require(
                logTransferToSelfCustody(selfCustodyAccount, token, amount),
                "LOG_FAIL_GRG_REQ_SATISFIED_ERROR"
                );
            return (true, shortfall);
        } else {
            return (false, shortfall);
        }
    }

    /// @dev external check if minimum pool GRG amount requirement satisfied.
    /// @param grgTokenAddress Address of the Rigo token.
    /// @param tokenAddress Address of the token to be transferred.
    /// @param amount Number of tokens to be transferred.
    /// @return satisfied Bool the transaction was successful.
    /// @return shortfall Number of GRG pool operator shortfall.
    /// @notice built around powers of pi number.
    function poolGRGminimumSatisfied (
        address grgTokenAddress,
        address tokenAddress,
        uint256 amount
    )
        external
        view
        returns (bool satisfied, uint256 shortfall)
    {
        return _poolGRGminimumSatisfied(grgTokenAddress, tokenAddress, amount);
    }

    /*
     * INTERNAL FUNCTIONS
     */
    /// @dev checks if minimum pool GRG amount requirement satisfied.
    /// @param grgTokenAddress Address of the Rigo token.
    /// @param tokenAddress Address of the token to be transferred.
    /// @param amount Number of tokens to be transferred.
    /// @return satisfied Bool the transaction was successful.
    /// @return shortfall Number of GRG pool operator shortfall.
    /// @notice built around powers of pi number.
    function _poolGRGminimumSatisfied(
        address grgTokenAddress,
        address tokenAddress,
        uint256 amount
    )
        internal
        view
        returns (bool satisfied, uint256 shortfall)
    {
        uint256 etherBase = 18;
        uint256 rationalBase = 36;
        uint256 rationalizedAmountBase36 = safeMul(amount, 10 ** (rationalBase - etherBase));
        uint256 poolRationalizedGrgBalanceBase36 = Token(grgTokenAddress).balanceOf(address(this)) * (10 ** (rationalBase - etherBase));

        if (tokenAddress != address(0)) {
            uint256 poolGrgBalance = Token(grgTokenAddress).balanceOf(address(this));
            satisfied = poolGrgBalance >= MIN_TOKEN_VALUE;
            shortfall = poolGrgBalance < MIN_TOKEN_VALUE ? MIN_TOKEN_VALUE - poolGrgBalance : uint256(0);

        } else if (rationalizedAmountBase36 < findPi2()) {
            if (poolRationalizedGrgBalanceBase36 < findPi4()) {
                satisfied = false;
                shortfall = safeDiv(findPi4() - poolRationalizedGrgBalanceBase36, (10 ** (rationalBase - etherBase)));
            } else {
                satisfied = true;
                shortfall = uint256(0);
            }

        } else if (rationalizedAmountBase36 < findPi3()) {
            if (poolRationalizedGrgBalanceBase36 < findPi5()) {
                satisfied = false;
                shortfall = safeDiv(findPi5() - poolRationalizedGrgBalanceBase36, (10 ** (rationalBase - etherBase)));
            } else {
                satisfied = true;
                shortfall = uint256(0);
            }

        } else if (rationalizedAmountBase36 >= findPi3()) {
            if (poolRationalizedGrgBalanceBase36 < findPi6()) {
                satisfied = false;
                shortfall = safeDiv(findPi6() - poolRationalizedGrgBalanceBase36, (10 ** (rationalBase - etherBase)));
            } else {
                satisfied = true;
                shortfall = uint256(0);
            }

        } else {
            revert("UNKNOWN_GRG_MINIMUM_ERROR");
        }

        return (satisfied, shortfall);
    }

    /// @dev returns the base 36 value of pi number.
    /// @return pi1 Value of pi.
    function findPi() internal pure returns (uint256 pi1) {
        uint8 power = 1;
        uint256 pi = 3141592;
        uint256 piBase = 6;
        uint256 rationalBase = 36;
        pi1 = pi ** power * 10 ** (rationalBase - piBase * power);
    }

    /// @dev returns the base 36 value of pi^2 number.
    /// @return pi2 Value of pi^2.
    function findPi2() internal pure returns (uint256 pi2) {
        uint8 power = 2;
        uint256 pi = 3141592;
        uint256 piBase = 6;
        uint256 rationalBase = 36;
        pi2 = pi ** power * 10 ** (rationalBase - piBase * power);
    }

    /// @dev returns the base 36 value of pi^3 number.
    /// @return pi3 Value of pi^3.
    function findPi3() internal pure returns (uint256 pi3) {
        uint8 power = 3;
        uint256 pi = 3141592;
        uint256 piBase = 6;
        uint256 rationalBase = 36;
        pi3 = pi ** power * 10 ** (rationalBase - piBase * power);
    }

    /// @dev returns the base 36 value of pi^4 number.
    /// @return pi4 Value of pi^4.
    function findPi4() internal pure returns (uint256 pi4) {
        uint8 power = 4;
        uint256 pi = 3141592;
        uint256 piBase = 6;
        uint256 rationalBase = 36;
        pi4 = pi ** power * 10 ** (rationalBase - piBase * power);
    }

    /// @dev returns the base 36 value of pi^5 number.
    /// @return pi5 Value of pi^5.
    function findPi5() internal pure returns (uint256 pi5) {
        uint8 power = 5;
        uint256 pi = 3141592;
        uint256 piBase = 6;
        uint256 rationalBase = 36;
        pi5 = pi ** power * 10 ** (rationalBase - piBase * power);
    }

    /// @dev returns the base 36 value of pi^6 number.
    /// @return pi6 Value of pi^6.
    function findPi6() internal pure returns (uint256 pi6) {
        uint8 power = 6;
        uint256 pi = 3141592;
        uint256 piBase = 6;
        uint256 rationalBase = 36;
        pi6 = pi ** power * 10 ** (rationalBase - piBase * power);
    }

    /// @dev prints a custom log of the transfer.
    /// @param selfCustodyAccount Address of the self custody account.
    /// @param token Address of the token transferred.
    /// @param amount Number of tokens.
    /// @return Bool the log is printed correctly.
    function logTransferToSelfCustody(
        address selfCustodyAccount,
        address token,
        uint256 amount)
        internal
        returns (bool)
    {
        DragoEventful events = DragoEventful(getDragoEventful());
        bytes4 methodHash = bytes4(keccak256("transferToSelfCustody(address,address,uint256)"));
        bytes memory encodedParams = abi.encode(
            address(this),
            selfCustodyAccount,
            token,
            amount
            );
        require(
            events.customDragoLog(methodHash, encodedParams),
            "ISSUE_IN_EVENTFUL"
            );
        return true;
    }

    /// @dev executes the ETH or token transfer.
    /// @param selfCustodyAccount Address of the self custody account.
    /// @param token Address of the target token.
    /// @param amount Number of tokens to be transferred.
    /// @return success Bool the transfer executed correctly.
    function transferToSelfCustodyInternal(
        address payable selfCustodyAccount,
        address token,
        uint256 amount)
        internal
        returns (bool success)
    {
        if (token == address(0)) {
            selfCustodyAccount.transfer(amount);
            success = true;
        } else {
            _safeTransfer(token, selfCustodyAccount, amount);
            success = true;
        }
        return success;
    }
    
    /// @dev executes a safe transfer to any ERC20 token
    /// @param token Address of the origin
    /// @param to Address of the target
    /// @param value Amount to transfer
    function _safeTransfer(address token, address to, uint value) private {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "RIGOBLOCK_TRANSFER_FAILED"
        );
    }

    /// @dev Gets the address of the logger contract.
    /// @return Address of the logger contrac.
    function getDragoEventful()
        internal
        view
        returns (address)
    {
        address dragoEvenfulAddress =
            Drago(
                address(this)
            ).getEventful();
        return dragoEvenfulAddress;
    }
}