/* solhint-disable not-rely-on-time, func-order */
pragma solidity 0.6.5;

import "../contracts_common/src/Libraries/SafeMathWithRequire.sol";
import "./LandToken.sol";
import "../contracts_common/src/Interfaces/ERC1155.sol";
import "../contracts_common/src/Interfaces/ERC20.sol";
import "../contracts_common/src/BaseWithStorage/MetaTransactionReceiver.sol";
import "../contracts_common/src/Interfaces/Medianizer.sol";
import "../ReferralValidator/ReferralValidator.sol";


/**
 * @title Estate Sale contract with referral that supports also DAI and ETH as payment
 * @notice This contract mananges the sale of our lands as Estates
 */
contract EstateSale is MetaTransactionReceiver, ReferralValidator {
    using SafeMathWithRequire for uint256;

    uint256 internal constant GRID_SIZE = 408; // 408 is the size of the Land
    uint256 internal constant daiPrice = 14400000000000000;

    ERC1155 internal immutable _asset;
    LandToken internal immutable _land;
    ERC20 internal immutable _sand;
    Medianizer private immutable _medianizer;
    ERC20 private immutable _dai;
    address internal immutable _estate;

    address payable internal _wallet;
    uint256 internal immutable _expiryTime;
    bytes32 internal immutable _merkleRoot;

    bool _sandEnabled = false;
    bool _etherEnabled = true;
    bool _daiEnabled = false;

    event LandQuadPurchased(
        address indexed buyer,
        address indexed to,
        uint256 indexed topCornerId,
        uint256 size,
        uint256 price,
        address token,
        uint256 amountPaid
    );

    constructor(
        address landAddress,
        address sandContractAddress,
        address initialMetaTx,
        address admin,
        address payable initialWalletAddress,
        bytes32 merkleRoot,
        uint256 expiryTime,
        address medianizerContractAddress,
        address daiTokenContractAddress,
        address initialSigningWallet,
        uint256 initialMaxCommissionRate,
        address estate,
        address asset
    ) public ReferralValidator(initialSigningWallet, initialMaxCommissionRate) {
        _land = LandToken(landAddress);
        _sand = ERC20(sandContractAddress);
        _setMetaTransactionProcessor(initialMetaTx, true);
        _wallet = initialWalletAddress;
        _merkleRoot = merkleRoot;
        _expiryTime = expiryTime;
        _medianizer = Medianizer(medianizerContractAddress);
        _dai = ERC20(daiTokenContractAddress);
        _admin = admin;
        _estate = estate;
        _asset = ERC1155(asset);
    }

    /// @dev set the wallet receiving the proceeds
    /// @param newWallet address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "receiving wallet cannot be zero address");
        require(msg.sender == _admin, "only admin can change the receiving wallet");
        _wallet = newWallet;
    }

    /// @dev enable/disable DAI payment for Lands
    /// @param enabled whether to enable or disable
    function setDAIEnabled(bool enabled) external {
        require(msg.sender == _admin, "only admin can enable/disable DAI");
        _daiEnabled = enabled;
    }

    /// @notice return whether DAI payments are enabled
    /// @return whether DAI payments are enabled
    function isDAIEnabled() external view returns (bool) {
        return _daiEnabled;
    }

    /// @notice enable/disable ETH payment for Lands
    /// @param enabled whether to enable or disable
    function setETHEnabled(bool enabled) external {
        require(msg.sender == _admin, "only admin can enable/disable ETH");
        _etherEnabled = enabled;
    }

    /// @notice return whether ETH payments are enabled
    /// @return whether ETH payments are enabled
    function isETHEnabled() external view returns (bool) {
        return _etherEnabled;
    }

    /// @dev enable/disable the specific SAND payment for Lands
    /// @param enabled whether to enable or disable
    function setSANDEnabled(bool enabled) external {
        require(msg.sender == _admin, "only admin can enable/disable SAND");
        _sandEnabled = enabled;
    }

    /// @notice return whether the specific SAND payments are enabled
    /// @return whether the specific SAND payments are enabled
    function isSANDEnabled() external view returns (bool) {
        return _sandEnabled;
    }

    function _checkValidity(
        address buyer,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        bytes32 salt,
        uint256[] memory assetIds,
        bytes32[] memory proof
    ) internal view {
        /* solium-disable-next-line security/no-block-members */
        require(block.timestamp < _expiryTime, "sale is over");
        require(buyer == msg.sender || _metaTransactionContracts[msg.sender], "not authorized");
        require(reserved == address(0) || reserved == buyer, "cannot buy reserved Land");
        bytes32 leaf = _generateLandHash(x, y, size, price, reserved, salt, assetIds);

        require(_verify(proof, leaf), "Invalid land provided");
    }

    function _mint(
        address buyer,
        address to,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        address token,
        uint256 tokenAmount
    ) internal {
        if (size == 1 || _estate == address(0)) {
            _land.mintQuad(to, size, x, y, "");
        } else {
            _land.mintQuad(_estate, size, x, y, abi.encode(to));
        }
        emit LandQuadPurchased(buyer, to, x + (y * GRID_SIZE), size, price, token, tokenAmount);
    }

    /**
     * @notice buy Land with SAND using the merkle proof associated with it
     * @param buyer address that perform the payment
     * @param to address that will own the purchased Land
     * @param reserved the reserved address (if any)
     * @param x x coordinate of the Land
     * @param y y coordinate of the Land
     * @param size size of the pack of Land to purchase
     * @param priceInSand price in SAND to purchase that Land
     * @param proof merkleProof for that particular Land
     */
    function buyLandWithSand(
        address buyer,
        address to,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 priceInSand,
        bytes32 salt,
        uint256[] calldata assetIds,
        bytes32[] calldata proof,
        bytes calldata referral
    ) external {
        require(_sandEnabled, "sand payments not enabled");
        _checkValidity(buyer, reserved, x, y, size, priceInSand, salt, assetIds, proof);

        handleReferralWithERC20(buyer, priceInSand, referral, _wallet, address(_sand));

        _mint(buyer, to, x, y, size, priceInSand, address(_sand), priceInSand);
        _sendAssets(to, assetIds);
    }

    /**
     * @notice buy Land with ETH using the merkle proof associated with it
     * @param buyer address that perform the payment
     * @param to address that will own the purchased Land
     * @param reserved the reserved address (if any)
     * @param x x coordinate of the Land
     * @param y y coordinate of the Land
     * @param size size of the pack of Land to purchase
     * @param priceInSand price in SAND to purchase that Land
     * @param proof merkleProof for that particular Land
     * @param referral the referral used by the buyer
     */
    function buyLandWithETH(
        address buyer,
        address to,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 priceInSand,
        bytes32 salt,
        uint256[] calldata assetIds,
        bytes32[] calldata proof,
        bytes calldata referral
    ) external payable {
        require(_etherEnabled, "ether payments not enabled");
        _checkValidity(buyer, reserved, x, y, size, priceInSand, salt, assetIds, proof);

        uint256 ETHRequired = getEtherAmountWithSAND(priceInSand);
        require(msg.value >= ETHRequired, "not enough ether sent");

        if (msg.value - ETHRequired > 0) {
            msg.sender.transfer(msg.value - ETHRequired); // refund extra
        }

        handleReferralWithETH(ETHRequired, referral, _wallet);

        _mint(buyer, to, x, y, size, priceInSand, address(0), ETHRequired);
        _sendAssets(to, assetIds);
    }

    /**
     * @notice buy Land with DAI using the merkle proof associated with it
     * @param buyer address that perform the payment
     * @param to address that will own the purchased Land
     * @param reserved the reserved address (if any)
     * @param x x coordinate of the Land
     * @param y y coordinate of the Land
     * @param size size of the pack of Land to purchase
     * @param priceInSand price in SAND to purchase that Land
     * @param proof merkleProof for that particular Land
     */
    function buyLandWithDAI(
        address buyer,
        address to,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 priceInSand,
        bytes32 salt,
        uint256[] calldata assetIds,
        bytes32[] calldata proof,
        bytes calldata referral
    ) external {
        require(_daiEnabled, "dai payments not enabled");
        _checkValidity(buyer, reserved, x, y, size, priceInSand, salt, assetIds, proof);

        uint256 DAIRequired = priceInSand.mul(daiPrice).div(1000000000000000000);

        handleReferralWithERC20(buyer, DAIRequired, referral, _wallet, address(_dai));

        _mint(buyer, to, x, y, size, priceInSand, address(_dai), DAIRequired);
        _sendAssets(to, assetIds);
    }

    /**
     * @notice Gets the expiry time for the current sale
     * @return The expiry time, as a unix epoch
     */
    function getExpiryTime() external view returns (uint256) {
        return _expiryTime;
    }

    /**
     * @notice Gets the Merkle root associated with the current sale
     * @return The Merkle root, as a bytes32 hash
     */
    function merkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    function _sendAssets(address to, uint256[] memory assetIds) internal {
        uint256[] memory values = new uint256[](assetIds.length);
        for (uint256 i = 0; i < assetIds.length; i++) {
            values[i] = 1;
        }
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }

    function _generateLandHash(
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        address reserved,
        bytes32 salt,
        uint256[] memory assetIds
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(x, y, size, price, reserved, salt, assetIds));
    }

    function _verify(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == _merkleRoot;
    }

    /**
     * @notice Returns the amount of ETH for a specific amount of SAND
     * @param sandAmount An amount of SAND
     * @return The amount of ETH
     */
    function getEtherAmountWithSAND(uint256 sandAmount) public view returns (uint256) {
        uint256 ethUsdPair = getEthUsdPair();
        return sandAmount.mul(daiPrice).div(ethUsdPair);
    }

    /**
     * @notice Gets the ETHUSD pair from the Medianizer contract
     * @return The pair as an uint256
     */
    function getEthUsdPair() internal view returns (uint256) {
        bytes32 pair = _medianizer.read();
        return uint256(pair);
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xbc197c81;
    }

    function withdrawAssets(
        address to,
        uint256[] calldata assetIds,
        uint256[] calldata values
    ) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        require(block.timestamp > _expiryTime, "SALE_NOT_OVER");
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }
}
