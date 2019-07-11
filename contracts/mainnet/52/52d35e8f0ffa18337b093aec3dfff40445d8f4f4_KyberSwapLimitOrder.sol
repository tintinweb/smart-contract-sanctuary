pragma solidity 0.5.9;

import "./KyberNetworkProxyInterface.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Withdrawable.sol";


contract KyberSwapLimitOrder is Withdrawable {

    //userAddress => concatenated token addresses => nonce
    mapping(address => mapping(uint256 => uint256)) public nonces;
    bool public tradeEnabled;
    KyberNetworkProxyInterface public kyberNetworkProxy;
    uint256 public constant MAX_DEST_AMOUNT = 2 ** 256 - 1;
    uint256 public constant PRECISION = 10**4;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    //Constructor
    constructor(
        address _admin,
        KyberNetworkProxyInterface _kyberNetworkProxy
    )
        public
        Withdrawable(_admin) {
            require(_admin != address(0));
            require(address(_kyberNetworkProxy) != address(0));

            kyberNetworkProxy = _kyberNetworkProxy;
        }

    event TradeEnabled(bool tradeEnabled);

    function enableTrade() external onlyAdmin {
        tradeEnabled = true;
        emit TradeEnabled(tradeEnabled);
    }

    function disableTrade() external onlyAdmin {
        tradeEnabled = false;
        emit TradeEnabled(tradeEnabled);
    }

    function listToken(ERC20 token)
        external
        onlyAdmin
    {
        require(address(token) != address(0));
        /*
        No need to set allowance to zero first, as there&#39;s only 1 scenario here (from zero to max allowance).
        No one else can set allowance on behalf of this contract to Kyber.
        */
        token.safeApprove(address(kyberNetworkProxy), MAX_DEST_AMOUNT);
    }

    struct VerifyParams {
        address user;
        uint8 v;
        uint256 concatenatedTokenAddresses;
        uint256 nonce;
        bytes32 hashedParams;
        bytes32 r;
        bytes32 s;
    }

    struct TradeInput {
        ERC20 srcToken;
        uint256 srcQty;
        ERC20 destToken;
        address payable destAddress;
        uint256 minConversionRate;
        uint256 feeInPrecision;
    }

    event LimitOrderExecute(address indexed user, uint256 nonce, address indexed srcToken,
        uint256 actualSrcQty, uint256 destAmount, address indexed destToken,
        address destAddress, uint256 feeInSrcTokenWei);

    function executeLimitOrder(
        address user,
        uint256 nonce,
        ERC20 srcToken,
        uint256 srcQty,
        ERC20 destToken,
        address payable destAddress,
        uint256 minConversionRate,
        uint256 feeInPrecision,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        onlyOperator
        external
    {
        require(tradeEnabled);

        VerifyParams memory verifyParams;
        verifyParams.user = user;
        verifyParams.concatenatedTokenAddresses = concatTokenAddresses(address(srcToken), address(destToken));
        verifyParams.nonce = nonce;
        verifyParams.hashedParams = keccak256(abi.encodePacked(
            user, nonce, srcToken, srcQty, destToken, destAddress, minConversionRate, feeInPrecision));
        verifyParams.v = v;
        verifyParams.r = r;
        verifyParams.s = s;
        require(verifyTradeParams(verifyParams));

        TradeInput memory tradeInput;
        tradeInput.srcToken = srcToken;
        tradeInput.srcQty = srcQty;
        tradeInput.destToken = destToken;
        tradeInput.destAddress = destAddress;
        tradeInput.minConversionRate = minConversionRate;
        tradeInput.feeInPrecision = feeInPrecision;
        trade(tradeInput, verifyParams);
    }

    event OldOrdersInvalidated(address user, uint256 concatenatedTokenAddresses, uint256 nonce);

    function invalidateOldOrders(uint256 concatenatedTokenAddresses, uint256 nonce) external {
        require(validAddressInNonce(nonce));
        require(isValidNonce(msg.sender, concatenatedTokenAddresses, nonce));
        updateNonce(msg.sender, concatenatedTokenAddresses, nonce);
        emit OldOrdersInvalidated(msg.sender, concatenatedTokenAddresses, nonce);
    }

    function concatTokenAddresses(address srcToken, address destToken) public pure returns (uint256) {
        return ((uint256(srcToken) >> 32) << 128) + (uint256(destToken) >> 32);
    }

    function validAddressInNonce(uint256 nonce) public view returns (bool) {
        //check that first 16 bytes in nonce corresponds to first 16 bytes of contract address
        return (nonce >> 128) == (uint256(address(this)) >> 32);
    }

    function isValidNonce(address user, uint256 concatenatedTokenAddresses, uint256 nonce) public view returns (bool) {
        return nonce > nonces[user][concatenatedTokenAddresses];
    }

    function verifySignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s, address user) public pure returns (bool) {
        //Users have to sign the message using wallets (Trezor, Ledger, Geth)
        //These wallets prepend a prefix to the data to prevent some malicious signing scheme
        //Eg. website that tries to trick users to sign an Ethereum message
        //https://ethereum.stackexchange.com/questions/15364/ecrecover-from-geth-and-web3-eth-sign
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s) == user;
    }

    //used SafeMath lib
    function deductFee(uint256 srcQty, uint256 feeInPrecision) public pure returns
    (uint256 actualSrcQty, uint256 feeInSrcTokenWei) {
        require(feeInPrecision <= 100 * PRECISION);
        feeInSrcTokenWei = srcQty.mul(feeInPrecision).div(100 * PRECISION);
        actualSrcQty = srcQty.sub(feeInSrcTokenWei);
    }

    event NonceUpdated(address user, uint256 concatenatedTokenAddresses, uint256 nonce);

    function updateNonce(address user, uint256 concatenatedTokenAddresses, uint256 nonce) internal {
        nonces[user][concatenatedTokenAddresses] = nonce;
        emit NonceUpdated(user, concatenatedTokenAddresses, nonce);
    }

    function verifyTradeParams(VerifyParams memory verifyParams) internal view returns (bool) {
        require(validAddressInNonce(verifyParams.nonce));
        require(isValidNonce(verifyParams.user, verifyParams.concatenatedTokenAddresses, verifyParams.nonce));
        require(verifySignature(
            verifyParams.hashedParams,
            verifyParams.v,
            verifyParams.r,
            verifyParams.s,
            verifyParams.user
            ));
        return true;
    }

    function trade(TradeInput memory tradeInput, VerifyParams memory verifyParams) internal {
        tradeInput.srcToken.safeTransferFrom(verifyParams.user, address(this), tradeInput.srcQty);
        uint256 actualSrcQty;
        uint256 feeInSrcTokenWei;
        (actualSrcQty, feeInSrcTokenWei) = deductFee(tradeInput.srcQty, tradeInput.feeInPrecision);

        updateNonce(verifyParams.user, verifyParams.concatenatedTokenAddresses, verifyParams.nonce);
        uint256 destAmount = kyberNetworkProxy.tradeWithHint(
            tradeInput.srcToken,
            actualSrcQty,
            tradeInput.destToken,
            tradeInput.destAddress,
            MAX_DEST_AMOUNT,
            tradeInput.minConversionRate,
            address(this), //walletId
            "PERM" //hint: only Permissioned reserves to be used
        );

        emit LimitOrderExecute(
            verifyParams.user,
            verifyParams.nonce,
            address(tradeInput.srcToken),
            actualSrcQty,
            destAmount,
            address(tradeInput.destToken),
            tradeInput.destAddress,
            feeInSrcTokenWei
        );
    }
}