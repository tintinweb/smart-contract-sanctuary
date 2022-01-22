// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./AccessControl.sol";


contract AccessControlMixin is AccessControl {
    string private _revertMsg;
    function _setupContractId(string memory contractId) internal {
        _revertMsg = string(abi.encodePacked(contractId, ": INSUFFICIENT_PERMISSIONS"));
    }

    modifier only(bytes32 role) {
        require(
            hasRole(role, _msgSender()),
            _revertMsg
        );
        _;
    }
}


interface IChildToken {
    function deposit(address user, bytes calldata depositData) external;
}


contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}


contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}


contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}


abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}


contract CarchainCoin is    
        ERC20,
        IChildToken,
        AccessControlMixin,
        NativeMetaTransaction,
        ContextMixin {
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");

    uint256 MAX_CAP = 100000000 * 10 ** 18;

    address PARTNERS_WALLET = 0xF625a26585ff67C983835b692b1b630CE9eE6736;
    address FIRST_SUPPORTERS_REWARDS = 0x501d21CecC4C21A2CAFE94324B889dFB1820f107;
    address FUTURE_TOKEN_SALE = 0x50d2314561A4367964dA9CDCD328ab9F0f2A0e5d;
    address COMPANY_RESERVE = 0x09fADf3FB90Ddf5267c6a450D52b7F730d7F61da;

    address LISANDRO = 0x21AdEbA018e8BA41Cf2d2b822Bfa33a1Fed27018;
    address MAURIZIO = 0x25DC66f98AC3D2f422DDa90F2c05F0a1F55c54d6;
    address PULLUMB = 0x995587183124005F9cFdC03db4F845469f360414;
    address ORNELLA = 0x32c2f004C5cBEbf436a90f5978b8CB12e5B8E711;
    address NOELIA = 0x7089A806fB2Ff48C2CA54Dc652ccAc52c7692a53;
    address ZEESHAN = 0xd239DC840E016Cca481fC36De978537F61073Dfe;
    address NOUMAN = 0x551021fb904082bc86F46C5B45E2D0280eB3864D;
    address PATRICIO = 0x35Ac9d7e528a3f71b173e1a0adc9C0dAa59f0f99;
    address ABU = 0x41001Ee9fcb6E104Fea12707AbB788EcA1271Cf5;
    address LUCIANA = 0x52A9583a543CAbDD06F61a524Fe0EEcfb31F16C8;

    address VEHICLE_TOKENIZATION = 0x4736713C26f7728B3D0740dF1E3E02bE60DC32D6;
    address DOCU_VERIFY = 0x3da29685e4E9621D466C2DE45Cd51236DF6bdf77;

    uint256 TOTAL_VEHICLE_TOKENIZATION = 1000 * 10 ** 18;
    uint256 TOTAL_DOCU_VERIFY = 50 * 10 ** 18;

    mapping (address => Vesting[]) public vestings;

    event TokensReleased(address indexed _to, uint256 _tokensReleased);

    struct Vesting {
        uint256 total;
        uint256 unlockDate;
        bool claimed;
    }

    constructor() ERC20('Carchain Coin', 'CCC')
    {
        _setupContractId("CarchainCoin");

        _grantRole(DEPOSITOR_ROLE, 0xb5505a6d998549090530911180f38aC5130101c6);
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        uint256 inOneYear = block.timestamp + 365 * 1 days;
        uint256 inTwoYears = inOneYear + 365 * 1 days;
        uint256 inThreeYears = inTwoYears + 365 * 1 days;
        uint256 inFourYears = inThreeYears + 365 * 1 days;

        _mint(PARTNERS_WALLET, 10000000 * 10 ** 18);
        _mint(FIRST_SUPPORTERS_REWARDS, 5000000 * 10 ** 18);
        _mint(FUTURE_TOKEN_SALE, 15500000 * 10 ** 18);

        //Company Reserves
        _mint(address(this), 8000000 * 10 ** 18);

        createVesting(COMPANY_RESERVE, 2000000 * 10 ** 18, inOneYear);
        createVesting(COMPANY_RESERVE, 2000000 * 10 ** 18, inTwoYears);
        createVesting(COMPANY_RESERVE, 2000000 * 10 ** 18, inThreeYears);
        createVesting(COMPANY_RESERVE, 2000000 * 10 ** 18, inFourYears);

        //Team Tokens
        _mint(address(this), 1500000 * 10 ** 18);

        createVesting(LISANDRO, 250000 * 10 ** 18, inOneYear);
        createVesting(LISANDRO, 250000 * 10 ** 18, inTwoYears);

        createVesting(MAURIZIO, 100000 * 10 ** 18, inOneYear);
        createVesting(MAURIZIO, 100000 * 10 ** 18, inTwoYears);

        createVesting(PULLUMB, 100000 * 10 ** 18, inOneYear);
        createVesting(PULLUMB, 100000 * 10 ** 18, inTwoYears);

        createVesting(ORNELLA, 100000 * 10 ** 18, inOneYear);
        createVesting(ORNELLA, 100000 * 10 ** 18, inTwoYears);

        createVesting(NOELIA, 100000 * 10 ** 18, inOneYear);
        createVesting(NOELIA, 100000 * 10 ** 18, inTwoYears);

        createVesting(ZEESHAN, 20000 * 10 ** 18, inOneYear);
        createVesting(ZEESHAN, 20000 * 10 ** 18, inTwoYears);

        createVesting(NOUMAN, 20000 * 10 ** 18, inOneYear);
        createVesting(NOUMAN, 20000 * 10 ** 18, inTwoYears);
        
        createVesting(PATRICIO, 20000 * 10 ** 18, inOneYear);
        createVesting(PATRICIO, 20000 * 10 ** 18, inTwoYears);
        
        createVesting(ABU, 20000 * 10 ** 18, inOneYear);
        createVesting(ABU, 20000 * 10 ** 18, inTwoYears);
        
        createVesting(LUCIANA, 20000 * 10 ** 18, inOneYear);
        createVesting(LUCIANA, 20000 * 10 ** 18, inTwoYears);
    }

    function mintForVehicleTokenization() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(totalSupply() + TOTAL_VEHICLE_TOKENIZATION < MAX_CAP, "Max cap surpased");

        _mint(VEHICLE_TOKENIZATION, TOTAL_VEHICLE_TOKENIZATION);
    }

    function mintForDocuVerify() public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(totalSupply() + TOTAL_DOCU_VERIFY < MAX_CAP, "Max cap surpased");

        _mint(DOCU_VERIFY, TOTAL_DOCU_VERIFY);
    }

    function getTotalToClaimNowByBeneficiary(address _beneficiary) public view returns(uint256) {
        uint256 total = 0;
        
        for (uint256 i = 0; i < vestings[_beneficiary].length; i++) {
            Vesting memory vesting = vestings[_beneficiary][i];
            if (!vesting.claimed && block.timestamp > vesting.unlockDate) {
                total += vesting.total;
            }
        }

        return total;
    }

    function claimVesting() external
    {
        uint256 tokensToClaim = getTotalToClaimNowByBeneficiary(_msgSender());
        require(tokensToClaim > 0, "Nothing to claim");
        
        for (uint256 i = 0; i < vestings[_msgSender()].length; i++) {
            Vesting storage vesting = vestings[_msgSender()][i];
            if (!vesting.claimed && block.timestamp > vesting.unlockDate) {
                vesting.claimed = true;
            }
        }

        _transfer(address(this), _msgSender(), tokensToClaim);
        emit TokensReleased(_msgSender(), tokensToClaim);
    }

    function createVesting(address _beneficiary, uint256 _totalTokens, uint256 _unlockDate) internal {
        Vesting memory vesting = Vesting(_totalTokens, _unlockDate, false);
        vestings[_beneficiary].push(vesting);
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        only(DEPOSITOR_ROLE)
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }
}