// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/token/ERC20/utils/SafeERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/token/ERC20/IERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/utils/cryptography/ECDSA.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// bisa pakai safeMath openzeppelin

/**
 * @dev Party Contract.
 * Becasue this smart contract use many off chain data for its transactions, there are needs
 * to make sure that the data came from the right source or valid. In this implementation we use Signature
 * method. In this smart contract, off chain data will be signed using the user's or the platform's
 * private key. But in order to minimize the cost only the RSV of said signature get sent to the
 * smart contract. The smart contract then must also receive signature's message combination alongside
 * the RSV in order to verify the signature.
 */

/**
 * @dev Member signature is deleted because the member is no need to be verified, because the signature
 * is always the same.
 */

//TODO: Remove calculateWeight

contract Party is Ownable {
    using SafeERC20 for IERC20;
    // Dummy USDC = 0xfD1e0d4662Ef8Ab1Ff675Da33b8be58A39436261
    // Ropsten USDC = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
    IERC20 token;
    // @dev no longer needed
    // address private OWNER; //Dont use immutable, becaue the value will be write to the bytecode
    address private immutable PLATFORM_ADDRESS;
    mapping(address => bool) private member;
    mapping(address => uint256) public balance;
    mapping(address => uint256) public weight;
    address[] public memberList;
    uint256 public balanceParty;
    mapping(string => address payable) public registeredProposal; //pointer id value address proposer, change to string because of uuid

    event DepositEvent(
        address caller,
        address partyAddress,
        uint256 amount,
        uint256 cut
    );

    event JoinEvent(
        address caller,
        address partyAddress,
        string joinPartyId,
        string userId,
        uint256 amount,
        uint256 cut
    );

    event CreateEvent(
        address caller,
        string partyName,
        string partyId,
        string ownerId
    );

    event ApprovePayerEvent(string proposalId, address[] payers);

    event WithdrawEvent(
        address caller,
        address partyAddress,
        uint256 amount,
        uint256 cut,
        uint256 penalty
    );

    event LeavePartyEvent(
        address userAddress,
        uint256 weight,
        address partyAddress,
        uint256 sent,
        uint256 cut,
        uint256 penalty
    );

    event KickPartyEvent(
        address userAddress,
        uint256 weight,
        address partyAddress,
        uint256 sent,
        uint256 cut,
        uint256 penalty
    );

    event ClosePartyEvent(address partyAddress, address ownerAddress);

    event Qoute0xSwap(
        IERC20 sellTokenAddress,
        IERC20 buyTokenAddress,
        address spender,
        address swapTarget,
        string transactionType,
        uint256 sellAmount,
        uint256 buyAmount,
        uint256 fee
    );

    struct Sig {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct PartyInfo {
        string idParty;
        string ownerId;
        address userAddress;
        address platform_Address;
        string typeP;
        string partyName;
        bool isPublic;
    }

    struct RangeDepth {
        uint256 minDeposit;
        uint256 maxDeposit;
    }

    struct Swap {
        IERC20 buyTokenAddress;
        IERC20 sellTokenAddress;
        address spender;
        address payable swapTarget;
        bytes swapCallData;
        uint256 sellAmount;
        uint256 buyAmount;
        Sig inputApproveRSV;
    }

    struct SwapWithoutRSV {
        IERC20 buyTokenAddress;
        IERC20 sellTokenAddress;
        address spender;
        address payable swapTarget;
        bytes swapCallData;
        uint256 sellAmount;
        uint256 buyAmount;
    }

    struct Weight {
        address weightAddress;
        uint256 weightPercentage;
    }

    RangeDepth public rangeDEP;
    Swap private swap;

    /**
     * @dev Create Party Message Combination
     * platform signature message :
     *  -  idParty:string
     *  -  userAddress:address
     *  -  platform_Address:address
     *  -  ownerId:string
     *  -  isPublic:bool
     */
    constructor(
        RangeDepth memory inputRangeDep,
        PartyInfo memory inputPartyInformation,
        Sig memory inputPlatformRSV,
        IERC20 stableCoin
    ) {
        rangeDEP = inputRangeDep;
        //  @dev removed because the person whe deploys is auto set to owner()
        //   OWNER = msg.sender;
        PLATFORM_ADDRESS = inputPartyInformation.platform_Address;
        token = IERC20(stableCoin);
        //platform verification purpose
        require(
            verifySigner(
                inputPartyInformation.platform_Address,
                messageHash(
                    abi.encodePacked(
                        inputPartyInformation.idParty,
                        inputPartyInformation.userAddress,
                        inputPartyInformation.platform_Address,
                        inputPartyInformation.ownerId,
                        inputPartyInformation.isPublic
                    )
                ),
                inputPlatformRSV
            ),
            "platform invalid"
        );
        emit CreateEvent(
            msg.sender,
            inputPartyInformation.partyName,
            inputPartyInformation.idParty,
            inputPartyInformation.ownerId
        );
    }

    function fillQuote(
        IERC20 sellTokenAddress,
        IERC20 buyTokenAddress,
        address spender,
        address payable swapTarget,
        bytes memory swapCallData,
        uint256 sellAmount,
        uint256 buyAmount,
        Sig memory inputApproveRSV
    ) public payable {
        require(
            verifySigner(
                PLATFORM_ADDRESS,
                messageHash(
                    abi.encodePacked(
                        sellTokenAddress,
                        buyTokenAddress,
                        spender,
                        swapTarget,
                        sellAmount,
                        buyAmount
                    )
                ),
                inputApproveRSV
            ),
            "Approve Signature Failed"
        );
        uint256 fee = (buyAmount * 5) / 1000;
        uint256 outAmount = sellAmount;
        require(
            outAmount <= sellTokenAddress.balanceOf(address(this)),
            "Balance not enough."
        );
        require(sellTokenAddress.approve(spender, type(uint256).max));
        (bool success, ) = swapTarget.call{value: msg.value}(swapCallData);
        require(success, "SWAP_CALL_FAILED");
        payable(msg.sender).transfer(address(this).balance);
        buyTokenAddress.safeTransfer(PLATFORM_ADDRESS, fee);
        sellTokenAddress.approve(spender, 0);
        if (sellTokenAddress == token) {
            emit Qoute0xSwap(
                sellTokenAddress,
                buyTokenAddress,
                spender,
                swapTarget,
                "BUY",
                sellAmount,
                buyAmount,
                fee
            );
        } else {
            emit Qoute0xSwap(
                sellTokenAddress,
                buyTokenAddress,
                spender,
                swapTarget,
                "SELL",
                sellAmount,
                buyAmount,
                fee
            );
        }
    }

    /**
     * @dev Withdraw Function
     * Withdraw function is for the user that want their money back.
     * //WORK IN PROGRESS
     */
    function withdraw(
        address partyAddress,
        uint256 amount,
        uint256 n,
        SwapWithoutRSV[] memory tokenData,
        Sig memory withdrawRSV
    ) external payable isAlive onlyMember {
        require(
            verifySigner(
                PLATFORM_ADDRESS,
                messageHash(abi.encodePacked(partyAddress, amount, n)),
                withdrawRSV
            ),
            "Withdraw platform signature invalid"
        );
        uint256 fee = 0;
        for (uint256 index = 0; index < tokenData.length; index++) {
            fee = (tokenData[index].buyAmount * 5) / 1000;
            uint256 outAmount = tokenData[index].sellAmount;
            require(
                outAmount <=
                    tokenData[index].sellTokenAddress.balanceOf(address(this)),
                "Balance not enough."
            );
            require(
                tokenData[index].sellTokenAddress.approve(
                    tokenData[index].spender,
                    type(uint256).max
                ),
                "Approval invalid"
            );
            (bool success, ) = tokenData[index].swapTarget.call{
                value: msg.value
            }(tokenData[index].swapCallData);
            require(success, "SWAP_CALL_FAILED");
            payable(msg.sender).transfer(address(this).balance);
            tokenData[index].buyTokenAddress.safeTransfer(
                PLATFORM_ADDRESS,
                fee
            );
            // tokenData[index].sellTokenAddress.approve(
            //     tokenData[index].spender,
            //     0
            // );
            emit Qoute0xSwap(
                tokenData[index].sellTokenAddress,
                tokenData[index].buyTokenAddress,
                tokenData[index].spender,
                tokenData[index].swapTarget,
                "SELL",
                tokenData[index].sellAmount,
                tokenData[index].buyAmount,
                fee
            );
        }
        require(
            amount <= token.balanceOf(address(this)),
            "Enter the correct Amount"
        );
        uint256 cut = (amount * 5) / 1000; // 1000 * 100000 = 100000000
        uint256 penalty = calculatePenalty(amount, n);
        uint256 sent = amount - cut - penalty;
        token.safeTransfer(PLATFORM_ADDRESS, cut + penalty);
        token.safeTransfer(msg.sender, sent);
        emit WithdrawEvent(msg.sender, partyAddress, amount, cut, penalty);
    }

    function getPartyBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Deposit Function
     * deposit function sents token to sc it self when triggred.
     * in order to trigger deposit function, user must be a member
     * you can see the modifier "onlyMember" inside deposit function
     * if the user is already on member list, then the function will be executed
     *
     */
    function deposit(address partyAddress, uint256 amount) external isAlive {
        uint256 cut = (amount * 5) / 1000;
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeTransferFrom(msg.sender, PLATFORM_ADDRESS, cut);
        emit DepositEvent(msg.sender, partyAddress, amount, cut);
    }

    /**
     * @dev Join Party Function
     *
     * join party function need rsv parameters and messages parameters from member
     * this both parameters is needed to do some validation within member it self, before the member can join party
     * when the user succeed joining party, users will be added to memberlist.
     *
     * platform signature message :
     *  - ownerAddress:address
     *  - partyAddress:address
     *  - joinPartyId:string
     */
    function joinParty(
        Sig memory inputJoinPartyPlatformRSV,
        address partyAddress,
        string memory userId,
        string memory joinPartyId,
        uint256 amount
    ) external isAlive notAMember reqDeposit(amount) {
        require(
            verifySigner(
                PLATFORM_ADDRESS,
                messageHash(
                    abi.encodePacked(msg.sender, partyAddress, joinPartyId)
                ),
                inputJoinPartyPlatformRSV
            ),
            "Transaction Signature Invalid"
        );
        require(!member[msg.sender], "Member is already registered.");
        memberList.push(msg.sender);
        member[msg.sender] = true;
        uint256 cut = (amount * 5) / 1000;
        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeTransferFrom(msg.sender, PLATFORM_ADDRESS, cut);
        emit JoinEvent(
            msg.sender,
            partyAddress,
            joinPartyId,
            userId,
            amount,
            cut
        );
    }

    function leaveParty(
        address quittingMember,
        uint256 addressWeight,
        uint256 n,
        SwapWithoutRSV[] memory tokenData,
        Sig memory leavePartyRSV
    ) external payable onlyMember isAlive {
        require(
            verifySigner(
                PLATFORM_ADDRESS,
                messageHash(abi.encodePacked(quittingMember, addressWeight)),
                leavePartyRSV
            ),
            "Withdraw platform signature invalid"
        );
        uint256 balanceBeforeSwap = getPartyBalance();
        swapPlaceHolder(tokenData);
        uint256 balanceDiff = getPartyBalance() - balanceBeforeSwap;
        uint256 _userBalance = ((balanceBeforeSwap * addressWeight) / 10**6) +
            balanceDiff;
        removeMember(quittingMember);
        uint256 cut = (_userBalance * 5) / 1000; // 1000 * 100000 = 100000000
        uint256 penalty = calculatePenalty(_userBalance, n);
        uint256 sent = _userBalance - cut - penalty;
        member[msg.sender] = false;
        token.safeTransfer(msg.sender, sent);
        token.safeTransfer(PLATFORM_ADDRESS, cut + penalty);
        emit LeavePartyEvent(
            quittingMember,
            addressWeight,
            address(this),
            _userBalance,
            cut,
            penalty
        );
    }

    function kickParty(
        address quittingMember,
        uint256 addressWeight,
        uint256 n,
        SwapWithoutRSV[] memory tokenData,
        Sig memory leavePartyRSV
    ) external payable onlyOwner isAlive {
        require(
            verifySigner(
                PLATFORM_ADDRESS,
                messageHash(abi.encodePacked(quittingMember, addressWeight)),
                leavePartyRSV
            ),
            "Withdraw platform signature invalid"
        );
        uint256 balanceBeforeSwap = getPartyBalance();
        swapPlaceHolder(tokenData);
        uint256 balanceDiff = getPartyBalance() - balanceBeforeSwap;
        uint256 _userBalance = ((balanceBeforeSwap * addressWeight) / 10**6) +
            balanceDiff;
        removeMember(quittingMember);
        uint256 cut = (_userBalance * 5) / 1000; // 1000 * 100000 = 100000000
        uint256 penalty = calculatePenalty(_userBalance, n);
        uint256 sent = _userBalance - cut - penalty;
        member[quittingMember] = false;
        token.safeTransfer(quittingMember, sent);
        token.safeTransfer(PLATFORM_ADDRESS, cut + penalty);
        emit KickPartyEvent(
            quittingMember,
            addressWeight,
            address(this),
            _userBalance,
            cut,
            penalty
        );
    }

    function swapPlaceHolder(SwapWithoutRSV[] memory tokenData)
        internal
        isAlive
        returns (uint256)
    {
        uint256 fee = 0;
        for (uint256 index = 0; index < tokenData.length; index++) {
            fee = (tokenData[index].buyAmount * 5) / 1000;
            uint256 outAmount = tokenData[index].sellAmount;
            require(
                outAmount <=
                    tokenData[index].sellTokenAddress.balanceOf(address(this)),
                "Balance not enough."
            );
            require(
                tokenData[index].sellTokenAddress.approve(
                    tokenData[index].spender,
                    type(uint256).max
                ),
                "Approval invalid"
            );
            (bool success, ) = tokenData[index].swapTarget.call{
                value: msg.value
            }(tokenData[index].swapCallData);
            require(success, "SWAP_CALL_FAILED");
            payable(msg.sender).transfer(address(this).balance);
            tokenData[index].buyTokenAddress.safeTransfer(
                PLATFORM_ADDRESS,
                fee
            );
            // tokenData[index].sellTokenAddress.approve(
            //     tokenData[index].spender,
            //     0
            // );
            emit Qoute0xSwap(
                tokenData[index].sellTokenAddress,
                tokenData[index].buyTokenAddress,
                tokenData[index].spender,
                tokenData[index].swapTarget,
                "SELL",
                tokenData[index].sellAmount,
                tokenData[index].buyAmount,
                fee
            );
        }
        return fee;
    }

    function closeParty(
        Weight[] memory weightArray,
        SwapWithoutRSV[] memory tokenData,
        Sig memory closePartyRSV
    ) external payable onlyOwner isAlive {
        require(owner() == msg.sender);
        require(
            verifySigner(
                PLATFORM_ADDRESS,
                messageHash(abi.encodePacked(msg.sender)),
                closePartyRSV
            ),
            "Withdraw platform signature invalid"
        );
        swapPlaceHolder(tokenData);
        uint256 fee = 0;
        //address _temp = OWNER;
        // OWNER = address(0x0);
        //@dev owner is now set to 0x0
        renounceOwnership();
        uint256 x = getPartyBalance();
        for (uint256 index = 0; index < weightArray.length; index++) {
            uint256 value = ((weightArray[index].weightPercentage * x) / 10**6);
            fee = (value * 5) / 1000;
            token.safeTransfer(weightArray[index].weightAddress, value - fee);
            token.safeTransfer(PLATFORM_ADDRESS, fee);
            emit LeavePartyEvent(
                weightArray[index].weightAddress,
                weightArray[index].weightPercentage,
                address(this),
                value,
                fee,
                0
            );
        }
        emit ClosePartyEvent(address(this), owner());
    }

    function calculatePenalty(uint256 _userBalance, uint256 n)
        private
        pure
        returns (uint256)
    {
        uint256 penalty;
        if (n != 0) {
            uint256 _temp = 17 * 10**8 + (n - 1) * 4160674157; //times 10 ** 10
            _temp = (_temp * 10**6) / 10**10;
            penalty = (_userBalance * _temp) / 10**8;
        } else {
            penalty = 0;
        }
        return penalty;
    }

    function removeMember(address quittingMember) private {
        for (uint256 index = 0; index < memberList.length; index++) {
            if (memberList[index] == quittingMember) {
                memberList[index] = memberList[memberList.length - 1];
                memberList.pop();
                break;
            }
        }
    }

    //    modifier onlyOwner() {
    //        require(msg.sender == OWNER, "not owner");
    //        _;
    //    }
    modifier onlyMember() {
        require(member[msg.sender], "havent join party yet");
        _;
    }
    modifier notAMember() {
        require(!member[msg.sender], "havent join party yet");
        _;
    }
    modifier isAlive() {
        require(owner() != address(0), "Party is dead");
        _;
    }

    /**
     * @dev reqDeposit function
     * to ensure the deposit value is correct and doesn't exceed the specified limit
     */
    modifier reqDeposit(uint256 amount) {
        require(!(amount < rangeDEP.minDeposit), "Deposit is not enough");
        require(!(amount > rangeDEP.maxDeposit), "Deposit is too many");
        _;
    }

    function messageHash(bytes memory abiEncode)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abiEncode)
                )
            );
    }

    function verifySigner(
        address signer,
        bytes32 ethSignedMessageHash,
        Sig memory inputRSV
    ) internal pure returns (bool) {
        return
            ECDSA.recover(
                ethSignedMessageHash,
                inputRSV.v,
                inputRSV.r,
                inputRSV.s
            ) == signer;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}