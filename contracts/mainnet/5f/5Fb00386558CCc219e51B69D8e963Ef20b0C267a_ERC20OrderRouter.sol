// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import {ETH} from "./constants/Tokens.sol";
import {IGelatoPineCore} from "./interfaces/IGelatoPineCore.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20OrderRouter {
    IGelatoPineCore public immutable gelatoPineCore;

    event DepositToken(
        bytes32 indexed key,
        address indexed caller,
        uint256 amount,
        address module,
        address inputToken,
        address indexed owner,
        address witness,
        bytes data,
        bytes32 secret
    );

    constructor(IGelatoPineCore _gelatoPineCore) {
        gelatoPineCore = _gelatoPineCore;
    }

    // solhint-disable max-line-length
    /** @dev To be backward compatible with old ERC20 Order submission
    * parameters are in format expected by subgraph:
    * https://github.com/gelatodigital/limit-orders-subgraph/blob/7614c138e462577475d240074000c60bad6b76cc/src/handlers/Order.ts#L58
    ERC20 transfer should have an extra data we use to identify a order.
    * A transfer with a order looks like:
    *
    * 0xa9059cbb
    * 000000000000000000000000c8b6046580622eb6037d5ef2ca74faf63dc93631
    * 0000000000000000000000000000000000000000000000000de0b6b3a7640000
    * 0000000000000000000000000000000000000000000000000000000000000060
    * 0000000000000000000000000000000000000000000000000000000000000120
    * 000000000000000000000000ef6c6b0bce4d2060efab0d16736c6ce7473deddc
    * 000000000000000000000000c7ad46e0b8a400bb3c915120d284aafba8fc4735
    * 0000000000000000000000005523f2fc0889a6d46ae686bcd8daa9658cf56496
    * 0000000000000000000000008153f16765f9124d754c432add5bd40f76f057b4
    * 00000000000000000000000000000000000000000000000000000000000000c0
    * 67656c61746f6e6574776f726b2020d83ddc09ea73fa863b164de440a270be31
    * 0000000000000000000000000000000000000000000000000000000000000060
    * 000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    * 00000000000000000000000000000000000000000000000004b1e20ebf83c000
    * 000000000000000000000000842A8Dea50478814e2bFAFF9E5A27DC0D1FdD37c
    *
    * The important part is 67656c61746f6e6574776f726b which is gelato's secret (gelatonetwork in hex)
    * We use that as the index to parse the input data:
    * - module = 5 * 32 bytes before secret index
    * - inputToken = ERC20 which emits the Transfer event
    * - owner = `from` parameter of the Transfer event
    * - witness = 2 * 32 bytes before secret index
    * - secret = 32 bytes from the secret index
    * - data = 2 * 32 bytes after secret index (64 or 96 bytes length). Contains:
    *   - outputToken =  2 * 32 bytes after secret index
    *   - minReturn =  3 * 32 bytes after secret index
    *   - handler =  4 * 32 bytes after secret index (optional)
    *
    */
    // solhint-disable function-max-lines
    function depositToken(
        uint256 _amount,
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data,
        bytes32 _secret
    ) external {
        require(
            _inputToken != ETH,
            "ERC20OrderRouter.depositToken: ONLY_ERC20"
        );

        bytes32 key =
            gelatoPineCore.keyOf(_module, _inputToken, _owner, _witness, _data);

        IERC20(_inputToken).transferFrom(
            msg.sender,
            gelatoPineCore.vaultOfOrder(
                _module,
                _inputToken,
                _owner,
                _witness,
                _data
            ),
            _amount
        );

        emit DepositToken(
            key,
            msg.sender,
            _amount,
            _module,
            _inputToken,
            _owner,
            _witness,
            _data,
            _secret
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface IGelatoPineCore {
    function vaultOfOrder(
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external view returns (address);

    function keyOf(
        address _module,
        address _inputToken,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external pure returns (bytes32);
}

