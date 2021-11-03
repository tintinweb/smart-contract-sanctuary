// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./interfaces/IVoucherKernel.sol";
import "./interfaces/IERC20WithPermit.sol";
import "./interfaces/ITokenRegistry.sol";
import "./interfaces/IBosonRouter.sol";
import "./interfaces/ICashier.sol";
import "./interfaces/IGate.sol";
import "./interfaces/ITokenWrapper.sol";
import {PaymentMethod} from "./UsingHelpers.sol";
import "./libs/SafeERC20WithPermit.sol";

/**
 * @title Contract for interacting with Boson Protocol from the user's perspective.
 * @notice There are multiple permutations of the requestCreateOrder and requestVoucher functions.
 * Each function name is suffixed with a payment type that denotes the currency type of the
 * payment and deposits. The options are:
 *
 * ETHETH  - Price and deposits are specified in ETH
 * ETHTKN - Price is specified in ETH and deposits are specified in tokens
 * TKNTKN - Price and deposits are specified in tokens
 * TKNETH - Price is specified in tokens and the deposits are specified in ETH
 *
 * The functions that process payments and/or deposits in tokens do so using EIP-2612 permit functionality
 *
 */
contract BosonRouter is
    IBosonRouter,
    Pausable,
    ReentrancyGuard,
    Ownable
{
    using Address for address payable;
    using SafeMath for uint256;

    address private cashierAddress;
    address private voucherKernel;
    address private tokenRegistry;

    mapping (address => bool) private approvedGates;
    mapping(uint256 => address) private voucherSetToGateContract;

    event LogOrderCreated(
        uint256 indexed _tokenIdSupply,
        address indexed _seller,
        uint256 _quantity,
        PaymentMethod _paymentType
    );

    event LogConditionalOrderCreated(
        uint256 indexed _tokenIdSupply,
        address indexed _gateAddress
    );

    event LogVoucherKernelSet(address _newVoucherKernel, address _triggeredBy);
    event LogTokenRegistrySet(address _newTokenRegistry, address _triggeredBy);
    event LogCashierSet(address _newCashier, address _triggeredBy);

    event LogGateApprovalChanged(
        address indexed _gateAddress,
        bool _approved
    );

    /**
     * @notice Make sure the given gate address is approved
     * @param _gateAddress - the address to validate approval for
     */
    modifier onlyApprovedGate(address _gateAddress) {
        require(approvedGates[_gateAddress], "INVALID_GATE");
        _;
    }

    /**
     * @notice Checking if a non-zero address is provided, otherwise reverts.
     */
    modifier notZeroAddress(address _tokenAddress) {
        require(_tokenAddress != address(0), "0A"); //zero address
        _;
    }

    /**
     * @notice Replacement of onlyOwner modifier. If the caller is not the owner of the contract, reverts.
     */
    modifier onlyRouterOwner() {
        require(owner() == _msgSender(), "NO"); //not owner
        _;
    }

    /**
     * @notice Acts as a modifier, but it's cheaper. Checks whether provided value corresponds to the limits in the TokenRegistry.
     * @param _value the specified value is per voucher set level. E.g. deposit * qty should not be greater or equal to the limit in the TokenRegistry (ETH).
     */
    function notAboveETHLimit(uint256 _value) internal view {
        require(
            _value <= ITokenRegistry(tokenRegistry).getETHLimit(),
            "AL" // above limit
        );
    }

    /**
     * @notice Acts as a modifier, but it's cheaper. Checks whether provided value corresponds to the limits in the TokenRegistry.
     * @param _tokenAddress the token address which, we are getting the limits for.
     * @param _value the specified value is per voucher set level. E.g. deposit * qty should not be greater or equal to the limit in the TokenRegistry (ETH).
     */
    function notAboveTokenLimit(address _tokenAddress, uint256 _value)
        internal
        view
    {
        require(
            _value <= ITokenRegistry(tokenRegistry).getTokenLimit(_tokenAddress),
            "AL" //above limit
        );
    }

    /**
     * @notice Construct and initialze the contract. Iniialises associated contract addresses
     * @param _voucherKernel address of the associated VocherKernal contract instance
     * @param _tokenRegistry address of the associated TokenRegistry contract instance
     * @param _cashierAddress address of the associated Cashier contract instance
     */
    constructor(
        address _voucherKernel,
        address _tokenRegistry,
        address _cashierAddress
    )   notZeroAddress(_voucherKernel)
        notZeroAddress(_tokenRegistry)
        notZeroAddress(_cashierAddress)
    {
        voucherKernel = _voucherKernel;
        tokenRegistry = _tokenRegistry;
        cashierAddress = _cashierAddress;
    }

    /**
     * @notice Set the approval status for a given Gate contract
     * @param _gateAddress - the address of the gate contract
     * @param _approved - approval status for the gate
     */
    function setGateApproval(address _gateAddress, bool _approved)
        external
        onlyOwner
        notZeroAddress(_gateAddress)
    {
        require(approvedGates[_gateAddress] != _approved, "NO_CHANGE");
        approvedGates[_gateAddress] = _approved;
        emit LogGateApprovalChanged(_gateAddress, _approved);
    }

    /**
     * @notice Pause the Cashier && the Voucher Kernel contracts in case of emergency.
     * All functions related to creating requestCreateOrder, requestVoucher, redeem, refund, complain, cancelOrFault,
     * cancelOrFaultVoucherSet, or withdraw will be paused and cannot be executed.
     * The withdrawEthOnDisaster function is a special function in the Cashier contract for withdrawing funds if contract is paused.
     */
    function pause() external override onlyRouterOwner() {
        _pause();
        if (!Pausable(voucherKernel).paused()) { 
            IVoucherKernel(voucherKernel).pause();
            ICashier(cashierAddress).pause();
        }
    }

    /**
     * @notice Unpause the Cashier && the Voucher Kernel contracts.
     * All functions related to creating requestCreateOrder, requestVoucher, redeem, refund, complain, cancelOrFault,
     * cancelOrFaultVoucherSet, or withdraw will be unpaused.
     */
    function unpause() external override onlyRouterOwner() {
        require(ICashier(cashierAddress).canUnpause(), "UF"); //unpaused forbidden

        _unpause();
        if (Pausable(voucherKernel).paused()) { 
            IVoucherKernel(voucherKernel).unpause();
            ICashier(cashierAddress).unpause();
        }        
    }

    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is
     * also known as a voucher set. Payment and deposits are specified in ETH.
     * @param _metadata metadata which is required for creation of a voucher set
     * Metadata array is used for consistency across the permutations of similar functions.
     * Some functions require other parameters, and the number of parameters causes stack too deep error.
     * The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     */
    function requestCreateOrderETHETH(uint256[] calldata _metadata)
        external
        payable
        virtual
        override
        nonReentrant
        whenNotPaused
    {
        checkLimits(_metadata, address(0), address(0), 0);
        requestCreateOrder(_metadata, PaymentMethod.ETHETH, address(0), address(0), 0);
    }

    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is also known as a voucher set.
     * The supply token/voucher set created should only be available to buyers who own a specific NFT (ERC115NonTransferrable) token.
     * This is the "condition" under which a buyer may commit to redeem a voucher that is part of the voucher set created by this function.
     * Payment and deposits are specified in ETH.
     * @param _metadata metadata which is required for creation of a voucher set
     * Metadata array is used for consistency across the permutations of similar functions.
     * Some functions require other parameters, and the number of parameters causes stack too deep error.
     * The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     *
     * @param _gateAddress address of a gate contract that will handle the interaction between the BosonRouter contract and the non-transferrable NFT,
     * ownership of which is a condition for committing to redeem a voucher in the voucher set created by this function.
     * @param _nftTokenId Id of the NFT (ERC115NonTransferrable) token, ownership of which is a condition for committing to redeem a voucher
     * in the voucher set created by this function.
     */
    function requestCreateOrderETHETHConditional(uint256[] calldata _metadata, address _gateAddress,
        uint256 _nftTokenId)
        external
        payable
        override
        nonReentrant
        whenNotPaused
        onlyApprovedGate(_gateAddress)
    {
        checkLimits(_metadata, address(0), address(0), 0);
        uint256 _tokenIdSupply = requestCreateOrder(_metadata, PaymentMethod.ETHETH, address(0), address(0), 0);
        finalizeConditionalOrder(_tokenIdSupply, _gateAddress, _nftTokenId);
    }


    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is
     * also known as a voucher set. Price and deposits are specified in tokens.
     * @param _tokenPriceAddress address of the token to be used for the price
     * @param _tokenDepositAddress address of the token to be used for the deposits
     * @param _tokensSent total number of tokens sent. Must be equal to seller deposit * quantity
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     * @param _metadata metadata which is required for creation of a voucher set
     * Metadata array is used for consistency across the permutations of similar functions.
     * Some functions require other parameters, and the number of parameters causes stack too deep error.
     * The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     */
    function requestCreateOrderTKNTKNWithPermit(
        address _tokenPriceAddress,
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata
    )
    external
    override
    nonReentrant
    {
        requestCreateOrderTKNTKNWithPermitInternal(
            _tokenPriceAddress,
            _tokenDepositAddress,
            _tokensSent,
            _deadline,
            _v,
            _r,
            _s,
            _metadata
        );
    }

    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is also known as a voucher set.
     * The supply token/voucher set created should only be available to buyers who own a specific NFT (ERC115NonTransferrable) token.
     * This is the "condition" under which a buyer may commit to redeem a voucher that is part of the voucher set created by this function.
     * Price and deposits are specified in tokens.
     * @param _tokenPriceAddress address of the token to be used for the price
     * @param _tokenDepositAddress address of the token to be used for the deposits
     * @param _tokensSent total number of tokens sent. Must be equal to seller deposit * quantity
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     * @param _metadata metadata which is required for creation of a voucher set
     * Metadata array is used for consistency across the permutations of similar functions.
     * Some functions require other parameters, and the number of parameters causes stack too deep error.
     * The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     *
     * @param _gateAddress address of a gate contract that will handle the interaction between the BosonRouter contract and the non-transferrable NFT,
     * ownership of which is a condition for committing to redeem a voucher in the voucher set created by this function.
     * @param _nftTokenId Id of the NFT (ERC115NonTransferrable) token, ownership of which is a condition for committing to redeem a voucher
     * in the voucher set created by this function.
     */
    function requestCreateOrderTKNTKNWithPermitConditional(
        address _tokenPriceAddress,
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata,
        address _gateAddress,
        uint256 _nftTokenId
    )
    external
    override
    nonReentrant
    onlyApprovedGate(_gateAddress)
    {
        uint256 tokenIdSupply = requestCreateOrderTKNTKNWithPermitInternal(
            _tokenPriceAddress,
            _tokenDepositAddress,
            _tokensSent,
            _deadline,
            _v,
            _r,
            _s,
            _metadata
        );

        finalizeConditionalOrder(tokenIdSupply, _gateAddress, _nftTokenId);
    }

    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is
     * also known as a voucher set. Price is specified in ETH and deposits are specified in tokens.
     * @param _tokenDepositAddress address of the token to be used for the deposits
     * @param _tokensSent total number of tokens sent. Must be equal to seller deposit * quantity
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     * @param _metadata metadata which is required for creation of a voucher set
     * Metadata array is used for consistency across the permutations of similar functions.
     * Some functions require other parameters, and the number of parameters causes stack too deep error.
     * The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     */
    function requestCreateOrderETHTKNWithPermit(
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata
    )
    external
    override
    nonReentrant
    {
        requestCreateOrderETHTKNWithPermitInternal( _tokenDepositAddress,
         _tokensSent,
         _deadline,
         _v,
         _r,
         _s,
        _metadata);

    }

    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is also known as a voucher set.
     * The supply token/voucher set created should only be available to buyers who own a specific NFT (ERC115NonTransferrable) token.
     * This is the "condition" under which a buyer may commit to redeem a voucher that is part of the voucher set created by this function.
     * Price is specified in ETH and deposits are specified in tokens.
     * @param _tokenDepositAddress address of the token to be used for the deposits
     * @param _tokensSent total number of tokens sent. Must be equal to seller deposit * quantity
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     * @param _metadata metadata which is required for creation of a voucher set
     * Metadata array is used for consistency across the permutations of similar functions.
     * Some functions require other parameters, and the number of parameters causes stack too deep error.
     * The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     *
     * @param _gateAddress address of a gate contract that will handle the interaction between the BosonRouter contract and the non-transferrable NFT,
     * ownership of which is a condition for committing to redeem a voucher in the voucher set created by this function.
     * @param _nftTokenId Id of the NFT (ERC115NonTransferrable) token, ownership of which is a condition for committing to redeem a voucher
     * in the voucher set created by this function.
     */
    function requestCreateOrderETHTKNWithPermitConditional(
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata,
        address _gateAddress,
        uint256 _nftTokenId
    )
    external
    override
    nonReentrant
    onlyApprovedGate(_gateAddress)
    {
        uint256 tokenIdSupply = requestCreateOrderETHTKNWithPermitInternal( _tokenDepositAddress,
         _tokensSent,
         _deadline,
         _v,
         _r,
         _s,
        _metadata);

        finalizeConditionalOrder(tokenIdSupply, _gateAddress, _nftTokenId);
    }

    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is
     * also known as a voucher set. Price is specified in tokens and the deposits are specified in ETH.
     * Since the price, which is specified in tokens, is not collected when a voucher set is created, there is no need to call
     * permit or transferFrom on the token at this time. The address of the price token is only recorded.
     * @param _tokenPriceAddress address of the token to be used for the deposits
     * @param _metadata metadata which is required for creation of a voucher set
     *  Metadata array is used for consistency across the permutations of similar functions.
     *  Some functions require other parameters, and the number of parameters causes stack too deep error.
     *  The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     */
    function requestCreateOrderTKNETH(
        address _tokenPriceAddress,
        uint256[] calldata _metadata
    )
    external
    payable
    override
    nonReentrant
    {
        requestCreateOrderTKNETHInternal(_tokenPriceAddress, _metadata);
    }

    /**
     * @notice Issuer/Seller offers promise as supply token and needs to escrow the deposit. A supply token is also known as a voucher set.
     * The supply token/voucher set created should only be available to buyers who own a specific NFT (ERC115NonTransferrable) token.
     * This is the "condition" under which a buyer may commit to redeem a voucher that is part of the voucher set created by this function.
     * Price is specified in tokens and the deposits are specified in ETH.
     * Since the price, which is specified in tokens, is not collected when a voucher set is created, there is no need to call
     * permit or transferFrom on the token at this time. The address of the price token is only recorded.
     * @param _tokenPriceAddress address of the token to be used for the deposits
     * @param _metadata metadata which is required for creation of a voucher set
     *  Metadata array is used for consistency across the permutations of similar functions.
     *  Some functions require other parameters, and the number of parameters causes stack too deep error.
     *  The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     *
     * @param _gateAddress address of a gate contract that will handle the interaction between the BosonRouter contract and the non-transferable NFT,
     * ownership of which is a condition for committing to redeem a voucher in the voucher set created by this function.
     * @param _nftTokenId Id of the NFT (ERC115NonTransferrable) token, ownership of which is a condition for committing to redeem a voucher
     * in the voucher set created by this function.
     */
    function requestCreateOrderTKNETHConditional(
        address _tokenPriceAddress,
        uint256[] calldata _metadata,
        address _gateAddress,
        uint256 _nftTokenId
    )
    external
    payable
    override
    nonReentrant
    onlyApprovedGate(_gateAddress)
    {
        uint256 tokenIdSupply = requestCreateOrderTKNETHInternal(_tokenPriceAddress, _metadata);
        finalizeConditionalOrder(tokenIdSupply, _gateAddress, _nftTokenId);
    }

    /**
     * @notice Buyer requests/commits to redeem a voucher and receives Voucher Token in return.
     * Price and deposit are specified in ETH
     * @param _tokenIdSupply    ID of the supply token
     * @param _issuer           Address of the issuer of the supply token
     */
    function requestVoucherETHETH(uint256 _tokenIdSupply, address _issuer)
    external
    payable
    override
    nonReentrant
    whenNotPaused
    {
        // check if _tokenIdSupply mapped to gate contract
        // if yes, deactivate (user,_tokenIdSupply) to prevent double spending
        deactivateConditionalCommit(_tokenIdSupply);

        uint256 weiReceived = msg.value;

        //checks
        (uint256 price, uint256 depositBu) = IVoucherKernel(voucherKernel)
            .getBuyerOrderCosts(_tokenIdSupply);
        require(price.add(depositBu) == weiReceived, "IF"); //invalid funds

        addEscrowAmountAndFillOrder(_tokenIdSupply, _issuer, PaymentMethod.ETHETH);
    }

    /**
     * @notice Buyer requests/commits to redeem a voucher and receives Voucher Token in return.
     * Price and deposit is specified in tokens.
     * @param _tokenIdSupply ID of the supply token
     * @param _issuer Address of the issuer of the supply token
     * @param _tokensSent total number of tokens sent. Must be equal to buyer deposit plus price
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _vPrice v signature component  used to verify the permit on the price token. See EIP-2612
     * @param _rPrice r signature component used to verify the permit on the price token. See EIP-2612
     * @param _sPrice s signature component used to verify the permit on the price token. See EIP-2612
     * @param _vDeposit v signature component  used to verify the permit on the deposit token. See EIP-2612
     * @param _rDeposit r signature component used to verify the permit on the deposit token. See EIP-2612
     * @param _sDeposit s signature component used to verify the permit on the deposit token. See EIP-2612
     */
    function requestVoucherTKNTKNWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _vPrice,
        bytes32 _rPrice,
        bytes32 _sPrice, // tokenPrice
        uint8 _vDeposit,
        bytes32 _rDeposit,
        bytes32 _sDeposit // tokenDeposits
    ) external override nonReentrant whenNotPaused {
        // check if _tokenIdSupply mapped to gate contract
        // if yes, deactivate (user,_tokenIdSupply) to prevent double spending
        deactivateConditionalCommit(_tokenIdSupply);

        (uint256 price, uint256 depositBu) = IVoucherKernel(voucherKernel)
            .getBuyerOrderCosts(_tokenIdSupply);
        require(_tokensSent.sub(depositBu) == price, "IF"); //invalid funds

        address tokenPriceAddress = IVoucherKernel(voucherKernel)
            .getVoucherPriceToken(_tokenIdSupply);
        address tokenDepositAddress = IVoucherKernel(voucherKernel)
            .getVoucherDepositToken(_tokenIdSupply);

        permitTransferFromAndAddEscrow(
            tokenPriceAddress,
            price,
            _deadline,
            _vPrice,
            _rPrice,
            _sPrice
        );

        permitTransferFromAndAddEscrow(
            tokenDepositAddress,
            depositBu,
            _deadline,
            _vDeposit,
            _rDeposit,
            _sDeposit
        );

        IVoucherKernel(voucherKernel).fillOrder(
            _tokenIdSupply,
            _issuer,
            msg.sender,
            PaymentMethod.TKNTKN
        );
    }

    /**
     * @notice Buyer requests/commits to redeem a voucher and receives Voucher Token in return.
     * Price and deposit is specified in tokens. The same token is used for both the price and deposit.
     * @param _tokenIdSupply ID of the supply token
     * @param _issuer address of the issuer of the supply token
     * @param _tokensSent total number of tokens sent. Must be equal to buyer deposit plus price
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     */
    function requestVoucherTKNTKNSameWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override nonReentrant whenNotPaused {
        // check if _tokenIdSupply mapped to gate contract
        // if yes, deactivate (user,_tokenIdSupply) to prevent double spending
        deactivateConditionalCommit(_tokenIdSupply);

        (uint256 price, uint256 depositBu) = IVoucherKernel(voucherKernel)
            .getBuyerOrderCosts(_tokenIdSupply);
        require(_tokensSent.sub(depositBu) == price, "IF"); //invalid funds

        address tokenPriceAddress = IVoucherKernel(voucherKernel)
            .getVoucherPriceToken(_tokenIdSupply);
        address tokenDepositAddress = IVoucherKernel(voucherKernel)
            .getVoucherDepositToken(_tokenIdSupply);

        require(tokenPriceAddress == tokenDepositAddress, "TOKENS_ARE_NOT_THE_SAME"); //invalid caller

        // If tokenPriceAddress && tokenPriceAddress are the same
        // practically it's not of importance to each we are sending the funds
        permitTransferFromAndAddEscrow(
            tokenPriceAddress,
            _tokensSent,
            _deadline,
            _v,
            _r,
            _s
        );

        IVoucherKernel(voucherKernel).fillOrder(
            _tokenIdSupply,
            _issuer,
            msg.sender,
            PaymentMethod.TKNTKN
        );
    }

    /**
     * @notice Buyer requests/commits to redeem a voucher and receives Voucher Token in return.
     * Price is specified in ETH and deposit is specified in tokens
     * @param _tokenIdSupply ID of the supply token
     * @param _issuer address of the issuer of the supply token
     * @param _tokensDeposit number of tokens sent to cover buyer deposit
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     */
    function requestVoucherETHTKNWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensDeposit,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable override nonReentrant whenNotPaused {
        // check if _tokenIdSupply mapped to gate contract
        // if yes, deactivate (user,_tokenIdSupply) to prevent double spending
        deactivateConditionalCommit(_tokenIdSupply);

        (uint256 price, uint256 depositBu) = IVoucherKernel(voucherKernel)
            .getBuyerOrderCosts(_tokenIdSupply);
        require(price == msg.value, "IP"); //invalid price
        require(depositBu == _tokensDeposit, "ID"); // invalid deposit

        address tokenDepositAddress = IVoucherKernel(voucherKernel)
            .getVoucherDepositToken(_tokenIdSupply);

        permitTransferFromAndAddEscrow(
            tokenDepositAddress,
            _tokensDeposit,
            _deadline,
            _v,
            _r,
            _s
        );

        addEscrowAmountAndFillOrder(_tokenIdSupply, _issuer, PaymentMethod.ETHTKN);
    }

    /**
     * @notice Buyer requests/commits to redeem a voucher and receives Voucher Token in return.
     * Price is specified in tokens and the deposit is specified in ETH
     * @param _tokenIdSupply ID of the supply token
     * @param _issuer address of the issuer of the supply token
     * @param _tokensPrice number of tokens sent to cover price
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     */
    function requestVoucherTKNETHWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensPrice,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable virtual override nonReentrant whenNotPaused {
        // check if _tokenIdSupply mapped to gate contract
        // if yes, deactivate (user,_tokenIdSupply) to prevent double spending
        deactivateConditionalCommit(_tokenIdSupply);

        (uint256 price, uint256 depositBu) = IVoucherKernel(voucherKernel)
            .getBuyerOrderCosts(_tokenIdSupply);
        require(price == _tokensPrice, "IP"); //invalid price
        require(depositBu == msg.value, "ID"); // invalid deposit

        address tokenPriceAddress = IVoucherKernel(voucherKernel)
            .getVoucherPriceToken(_tokenIdSupply);        

        permitTransferFromAndAddEscrow(
            tokenPriceAddress,
            price,
            _deadline,
            _v,
            _r,
            _s
        );

        addEscrowAmountAndFillOrder(_tokenIdSupply, _issuer, PaymentMethod.TKNETH);
    }

    /**
     * @notice Seller burns the remaining supply in the voucher set in case it's s/he no longer wishes to sell them.
     * Remaining seller deposit in escrow account is withdrawn and sent back to the seller
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) which will be burned and for which deposits will be returned
     */
    function requestCancelOrFaultVoucherSet(uint256 _tokenIdSupply)
        external
        override
        nonReentrant
        whenNotPaused
    {
        uint256 _burnedSupplyQty = IVoucherKernel(voucherKernel)
            .cancelOrFaultVoucherSet(_tokenIdSupply, msg.sender);
        ICashier(cashierAddress).withdrawDepositsSe(
            _tokenIdSupply,
            _burnedSupplyQty,
            msg.sender
        );
    }

    /**
     * @notice Redemption of the vouchers promise
     * @param _tokenIdVoucher   ID of the voucher
     */
    function redeem(uint256 _tokenIdVoucher) external override {
        IVoucherKernel(voucherKernel).redeem(_tokenIdVoucher, msg.sender);
    }

    /**
     * @notice Refunding a voucher
     * @param _tokenIdVoucher   ID of the voucher
     */
    function refund(uint256 _tokenIdVoucher) external override {
        IVoucherKernel(voucherKernel).refund(_tokenIdVoucher, msg.sender);
    }

    /**
     * @notice Issue a complaint for a voucher
     * @param _tokenIdVoucher   ID of the voucher
     */
    function complain(uint256 _tokenIdVoucher) external override {
        IVoucherKernel(voucherKernel).complain(_tokenIdVoucher, msg.sender);
    }

    /**
     * @notice Cancel/Fault transaction by the Seller, admitting to a fault or backing out of the deal
     * @param _tokenIdVoucher   ID of the voucher
     */
    function cancelOrFault(uint256 _tokenIdVoucher) external override {
        IVoucherKernel(voucherKernel).cancelOrFault(
            _tokenIdVoucher,
            msg.sender
        );
    }

    /**
     * @notice Get the address of Cashier contract
     * @return Address of Cashier address
     */
    function getCashierAddress() external view override returns (address) {
        return cashierAddress;
    }

    /**
     * @notice Get the address of Voucher Kernel contract
     * @return Address of Voucher Kernel contract
     */
    function getVoucherKernelAddress()
        external
        view
        override
        returns (address)
    {
        return voucherKernel;
    }

    /**
     * @notice Get the address of Token Registry contract
     * @return Address of Token Registrycontract
     */
    function getTokenRegistryAddress()
        external
        view
        override
        returns (address)
    {
        return tokenRegistry;
    }

    /**
     * @notice Get the address of the gate contract that handles conditional commit of certain voucher set
     * @param _tokenIdSupply    ID of the supply token
     * @return Address of the gate contract or zero address if there is no conditional commit
     */
    function getVoucherSetToGateContract(uint256 _tokenIdSupply)
        external
        view
        override
        returns (address)
    {
        return voucherSetToGateContract[_tokenIdSupply];
    }

    /**
     * @notice Call permit on either a token directly or on a token wrapper
     * @param _token Address of the token owner who is approving tokens to be transferred by spender
     * @param _tokenOwner Address of the token owner who is approving tokens to be transferred by spender
     * @param _spender Address of the party who is transferring tokens on owner's behalf
     * @param _value Number of tokens to be transferred
     * @param _deadline Time after which this permission to transfer is no longer valid. See EIP-2612
     * @param _v Part of the owner's signatue. See EIP-2612
     * @param _r Part of the owner's signatue. See EIP-2612
     * @param _s Part of the owner's signatue. See EIP-2612
     */
    function _permit(
        address _token,
        address _tokenOwner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        address tokenWrapper = ITokenRegistry(tokenRegistry)
            .getTokenWrapperAddress(_token);
        require(tokenWrapper != address(0), "UNSUPPORTED_TOKEN");

        //The BosonToken contract conforms to this spec, so it will be callable this way
        //if it's address is mapped to itself in the TokenRegistry
        ITokenWrapper(tokenWrapper).permit(
            _tokenOwner,
            _spender,
            _value,
            _deadline,
            _v,
            _r,
            _s
        );
    }

    /**
     * @notice Add amount to escrow and fill order (only order, were ETH involved)
     * @param _tokenIdSupply    ID of the supply token
     * @param _issuer           Address of the issuer of the supply token
     * * @param _paymentMethod  might be ETHETH, ETHTKN, TKNETH
     */    
    function addEscrowAmountAndFillOrder(uint256 _tokenIdSupply, address _issuer, PaymentMethod _paymentMethod) internal {
        //record funds in escrow ...
        ICashier(cashierAddress).addEscrowAmount{value: msg.value}(msg.sender);

        // fill order
        IVoucherKernel(voucherKernel).fillOrder(
            _tokenIdSupply,
            _issuer,
            msg.sender,
            _paymentMethod
        );        
    }

    /**
     * @notice Transfer tokens to cashier and adds it to escrow
     * @param _tokenAddress tokens that are transfered
     * @param _amount       amount of tokens to transfer (expected permit)
     */
    function transferFromAndAddEscrow(address _tokenAddress, uint256 _amount)
        internal
    {
        SafeERC20WithPermit.safeTransferFrom(
            IERC20WithPermit(_tokenAddress),
            msg.sender,
            address(cashierAddress),
            _amount
        );

        ICashier(cashierAddress).addEscrowTokensAmount(
            _tokenAddress,
            msg.sender,
            _amount
        );
    }

    /**
     * @notice Calls token that implements permits, transfer tokens from there to cashier and adds it to escrow
     * @param _tokenAddress tokens that are transfered
     * @param _amount       amount of tokens to transfer
     * @param _deadline Time after which this permission to transfer is no longer valid
     * @param _v Part of the owner's signatue
     * @param _r Part of the owner's signatue
     * @param _s Part of the owner's signatue
     */
    function permitTransferFromAndAddEscrow(
        address _tokenAddress,
        uint256 _amount,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal {
        _permit(
            _tokenAddress,
            msg.sender,
            address(this),
            _amount,
            _deadline,
            _v,
            _r,
            _s
        );

        transferFromAndAddEscrow(_tokenAddress, _amount);
    }

    /**
     * @notice Checks if supplied values are within set limits
     *  @param _metadata metadata which is required for creation of a voucher
     *  Metadata array is used as in some scenarios we need several more params, as we need to recover
     *  owner address in order to permit the contract to transfer funds on his behalf.
     *  Since the params get too many, we end up in situation that the stack is too deep.
     *
     *  uint256 _validFrom = _metadata[0];
     *  uint256 _validTo = _metadata[1];
     *  uint256 _price = _metadata[2];
     *  uint256 _depositSe = _metadata[3];
     *  uint256 _depositBu = _metadata[4];
     *  uint256 _quantity = _metadata[5];
     * @param _tokenPriceAddress     token address which will hold the funds for the price of the voucher
     * @param _tokenDepositAddress  token address which will hold the funds for the deposits of the voucher
     * @param _tokensSent     tokens sent to cashier contract
     */
    function checkLimits(
        uint256[] calldata _metadata,
        address _tokenPriceAddress,
        address _tokenDepositAddress,
        uint256 _tokensSent
    ) internal view {
        // check price limits. If price address == 0 -> prices in ETH
        if (_tokenPriceAddress == address(0)) {
            notAboveETHLimit(_metadata[2].mul(_metadata[5]));
        } else {
            notAboveTokenLimit(
                _tokenPriceAddress,
                _metadata[2].mul(_metadata[5])
            );
        }

        // check deposit limits. If deposit address == 0 -> deposits in ETH
        if (_tokenDepositAddress == address(0)) {
            notAboveETHLimit(_metadata[3].mul(_metadata[5]));
            notAboveETHLimit(_metadata[4].mul(_metadata[5]));
            require(_metadata[3].mul(_metadata[5]) == msg.value, "IF"); //invalid funds
        } else {
            notAboveTokenLimit(
                _tokenDepositAddress,
                _metadata[3].mul(_metadata[5])
            );
            notAboveTokenLimit(
                _tokenDepositAddress,
                _metadata[4].mul(_metadata[5])
            );
            require(_metadata[3].mul(_metadata[5]) == _tokensSent, "IF"); //invalid funds
        }
    }

    /**
     * @notice Internal function called by other TKNTKN requestCreateOrder functions to decrease code duplication.
     * Price and deposits are specified in tokens.
     * @param _tokenPriceAddress address of the token to be used for the price
     * @param _tokenDepositAddress address of the token to be used for the deposits
     * @param _tokensSent total number of tokens sent. Must be equal to seller deposit * quantity
     * @param _deadline deadline after which permit signature is no longer valid. See EIP-2612
     * @param _v signature component used to verify the permit. See EIP-2612
     * @param _r signature component used to verify the permit. See EIP-2612
     * @param _s signature component used to verify the permit. See EIP-2612
     * @param _metadata metadata which is required for creation of a voucher set
     * Metadata array is used for consistency across the permutations of similar functions.
     * Some functions require other parameters, and the number of parameters causes stack too deep error.
     * The use of the matadata array mitigates the stack too deep error.
     *
     * uint256 _validFrom = _metadata[0];
     * uint256 _validTo = _metadata[1];
     * uint256 _price = _metadata[2];
     * uint256 _depositSe = _metadata[3];
     * uint256 _depositBu = _metadata[4];
     * uint256 _quantity = _metadata[5];
     */
    function requestCreateOrderTKNTKNWithPermitInternal(
        address _tokenPriceAddress,
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata
    ) internal whenNotPaused notZeroAddress(_tokenPriceAddress) notZeroAddress(_tokenDepositAddress) returns (uint256) {
        checkLimits(
            _metadata,
            _tokenPriceAddress,
            _tokenDepositAddress,
            _tokensSent
        );

        _permit(
            _tokenDepositAddress,
            msg.sender,
            address(this),
            _tokensSent,
            _deadline,
            _v,
            _r,
            _s
        );

        return
            requestCreateOrder(
                _metadata,
                PaymentMethod.TKNTKN,
                _tokenPriceAddress,
                _tokenDepositAddress,
                _tokensSent
            );
    }

    function requestCreateOrderETHTKNWithPermitInternal(
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata
    ) internal whenNotPaused notZeroAddress(_tokenDepositAddress) returns (uint256) {
        checkLimits(_metadata, address(0), _tokenDepositAddress, _tokensSent);

        _permit(
            _tokenDepositAddress,
            msg.sender,
            address(this),
            _tokensSent,
            _deadline,
            _v,
            _r,
            _s
        );

        return requestCreateOrder(
            _metadata,
            PaymentMethod.ETHTKN,
            address(0),
            _tokenDepositAddress,
            _tokensSent
        );
    }

    function requestCreateOrderTKNETHInternal(
        address _tokenPriceAddress,
        uint256[] calldata _metadata
    ) internal whenNotPaused notZeroAddress(_tokenPriceAddress) returns (uint256) {
        checkLimits(_metadata, _tokenPriceAddress, address(0), 0);

        return requestCreateOrder(_metadata, PaymentMethod.TKNETH, _tokenPriceAddress, address(0), 0);
    }

    /**
     * @notice Internal helper that
     * - creates Token Supply Id
     * - creates payment method
     * - adds escrow ammount
     * - transfers tokens (if needed)
     * @param _metadata metadata which is required for creation of a voucher
     *  Metadata array is used as in some scenarios we need several more params, as we need to recover
     *  owner address in order to permit the contract to transfer funds on his behalf.
     *  Since the params get too many, we end up in situation that the stack is too deep.
     *
     *  uint256 _validFrom = _metadata[0];
     *  uint256 _validTo = _metadata[1];
     *  uint256 _price = _metadata[2];
     *  uint256 _depositSe = _metadata[3];
     *  uint256 _depositBu = _metadata[4];
     *  uint256 _quantity = _metadata[5];
     * @param _paymentMethod  might be ETHETH, ETHTKN, TKNETH or TKNTKN
     * @param _tokenPriceAddress     token address which will hold the funds for the price of the voucher
     * @param _tokenDepositAddress  token address which will hold the funds for the deposits of the voucher
     * @param _tokensSent     tokens sent to cashier contract
     */
    function requestCreateOrder(
        uint256[] calldata _metadata,
        PaymentMethod _paymentMethod,
        address _tokenPriceAddress,
        address _tokenDepositAddress,
        uint256 _tokensSent
    ) internal returns (uint256) {
        //record funds in escrow ...
        if (_tokenDepositAddress == address(0)) {
            ICashier(cashierAddress).addEscrowAmount{value: msg.value}(
                msg.sender
            );
        } else {
            transferFromAndAddEscrow(_tokenDepositAddress, _tokensSent);
        }
        
        uint256 tokenIdSupply = IVoucherKernel(voucherKernel)
            .createTokenSupplyId(
                msg.sender,
                _metadata[0],
                _metadata[1],
                _metadata[2],
                _metadata[3],
                _metadata[4],
                _metadata[5]
            );

        IVoucherKernel(voucherKernel).createPaymentMethod(
            tokenIdSupply,
            _paymentMethod,
            _tokenPriceAddress,
            _tokenDepositAddress
        );              

        emit LogOrderCreated(
            tokenIdSupply,
            msg.sender,
            _metadata[5],
            _paymentMethod
        );

        return tokenIdSupply;
    }

    /**
     * @notice finalizes creating of conditional order
     * @param _tokenIdSupply    ID of the supply token
     * @param _gateAddress address of a gate contract that will handle the interaction between the BosonRouter contract and the non-transferrable NFT,
     * ownership of which is a condition for committing to redeem a voucher in the voucher set created by this function.
     * @param _nftTokenId Id of the NFT (ERC115NonTransferrable) token, ownership of which is a condition for committing to redeem a voucher
     * in the voucher set created by this function.
     */
    function finalizeConditionalOrder(uint256 _tokenIdSupply, address _gateAddress, uint256 _nftTokenId) internal {
        voucherSetToGateContract[_tokenIdSupply] = _gateAddress;

        emit LogConditionalOrderCreated(_tokenIdSupply, _gateAddress);

        if (_nftTokenId > 0) {
            IGate(_gateAddress).registerVoucherSetId(
                _tokenIdSupply,
                _nftTokenId
            );
        }
    }

    /**
     * @notice check if _tokenIdSupply mapped to gate contract,
     * if it does, deactivate (user,_tokenIdSupply) to prevent double spending
     * @param _tokenIdSupply    ID of the supply token
     */
    function deactivateConditionalCommit(uint256 _tokenIdSupply) internal {
        if (voucherSetToGateContract[_tokenIdSupply] != address(0)) {
            IGate gateContract = IGate(
                voucherSetToGateContract[_tokenIdSupply]
            );
            require(gateContract.check(msg.sender, _tokenIdSupply),"NE"); // not eligible
            gateContract.deactivate(msg.sender, _tokenIdSupply);
        }
    }

    /**
     * @notice Set the address of the VoucherKernel contract
     * @param _voucherKernelAddress   The address of the VoucherKernel contract
     */
    function setVoucherKernelAddress(address _voucherKernelAddress)
        external
        onlyOwner
        notZeroAddress(_voucherKernelAddress)
        whenPaused
    {
        voucherKernel = _voucherKernelAddress;

        emit LogVoucherKernelSet(_voucherKernelAddress, msg.sender);
    }

    /**
     * @notice Set the address of the TokenRegistry contract
     * @param _tokenRegistryAddress   The address of the TokenRegistry contract
     */
    function setTokenRegistryAddress(address _tokenRegistryAddress)
        external
        onlyOwner
        notZeroAddress(_tokenRegistryAddress)
        whenPaused
    {
        tokenRegistry = _tokenRegistryAddress;

        emit LogTokenRegistrySet(_tokenRegistryAddress, msg.sender);
    }

    /**
     * @notice Set the address of the Cashier contract
     * @param _cashierAddress   The address of the Cashier contract
     */
    function setCashierAddress(address _cashierAddress)
        external
        onlyOwner
        notZeroAddress(_cashierAddress)
        whenPaused
    {
        cashierAddress = _cashierAddress;

        emit LogCashierSet(_cashierAddress, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.6;

import "./../UsingHelpers.sol";

interface IVoucherKernel {
    /**
     * @notice Pause the process of interaction with voucherID's (ERC-721), in case of emergency.
     * Only Cashier contract is in control of this function.
     */
    function pause() external;

    /**
     * @notice Unpause the process of interaction with voucherID's (ERC-721).
     * Only Cashier contract is in control of this function.
     */
    function unpause() external;

    /**
     * @notice Creating a new promise for goods or services.
     * Can be reused, e.g. for making different batches of these (but not in prototype).
     * @param _seller      seller of the promise
     * @param _validFrom   Start of valid period
     * @param _validTo     End of valid period
     * @param _price       Price (payment amount)
     * @param _depositSe   Seller's deposit
     * @param _depositBu   Buyer's deposit
     */
    function createTokenSupplyId(
        address _seller,
        uint256 _validFrom,
        uint256 _validTo,
        uint256 _price,
        uint256 _depositSe,
        uint256 _depositBu,
        uint256 _quantity
    ) external returns (uint256);

    /**
     * @notice Creates a Payment method struct recording the details on how the seller requires to receive Price and Deposits for a certain Voucher Set.
     * @param _tokenIdSupply     _tokenIdSupply of the voucher set this is related to
     * @param _paymentMethod  might be ETHETH, ETHTKN, TKNETH or TKNTKN
     * @param _tokenPrice   token address which will hold the funds for the price of the voucher
     * @param _tokenDeposits   token address which will hold the funds for the deposits of the voucher
     */
    function createPaymentMethod(
        uint256 _tokenIdSupply,
        PaymentMethod _paymentMethod,
        address _tokenPrice,
        address _tokenDeposits
    ) external;

    /**
     * @notice Mark voucher token that the payment was released
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function setPaymentReleased(uint256 _tokenIdVoucher) external;

    /**
     * @notice Mark voucher token that the deposits were released
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function setDepositsReleased(uint256 _tokenIdVoucher) external;

    /**
     * @notice Redemption of the vouchers promise
     * @param _tokenIdVoucher   ID of the voucher
     * @param _messageSender owner of the voucher
     */
    function redeem(uint256 _tokenIdVoucher, address _messageSender) external;

    /**
     * @notice Refunding a voucher
     * @param _tokenIdVoucher   ID of the voucher
     * @param _messageSender owner of the voucher
     */
    function refund(uint256 _tokenIdVoucher, address _messageSender) external;

    /**
     * @notice Issue a complain for a voucher
     * @param _tokenIdVoucher   ID of the voucher
     * @param _messageSender owner of the voucher
     */
    function complain(uint256 _tokenIdVoucher, address _messageSender) external;

    /**
     * @notice Cancel/Fault transaction by the Seller, admitting to a fault or backing out of the deal
     * @param _tokenIdVoucher   ID of the voucher
     * @param _messageSender owner of the voucher set (seller)
     */
    function cancelOrFault(uint256 _tokenIdVoucher, address _messageSender)
        external;

    /**
     * @notice Cancel/Fault transaction by the Seller, cancelling the remaining uncommitted voucher set so that seller prevents buyers from committing to vouchers for items no longer in exchange.
     * @param _tokenIdSupply   ID of the voucher
     * @param _issuer   owner of the voucher
     */
    function cancelOrFaultVoucherSet(uint256 _tokenIdSupply, address _issuer)
        external
        returns (uint256);

    /**
     * @notice Fill Voucher Order, iff funds paid, then extract & mint NFT to the voucher holder
     * @param _tokenIdSupply   ID of the supply token (ERC-1155)
     * @param _issuer          Address of the token's issuer
     * @param _holder          Address of the recipient of the voucher (ERC-721)
     * @param _paymentMethod   method being used for that particular order that needs to be fulfilled
     */
    function fillOrder(
        uint256 _tokenIdSupply,
        address _issuer,
        address _holder,
        PaymentMethod _paymentMethod
    ) external;

    /**
     * @notice Mark voucher token as expired
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function triggerExpiration(uint256 _tokenIdVoucher) external;

    /**
     * @notice Mark voucher token to the final status
     * @param _tokenIdVoucher   ID of the voucher token
     */
    function triggerFinalizeVoucher(uint256 _tokenIdVoucher) external;

    /**
     * @notice Set the address of the new holder of a _tokenIdSupply on transfer
     * @param _tokenIdSupply   _tokenIdSupply which will be transferred
     * @param _newSeller   new holder of the supply
     */
    function setSupplyHolderOnTransfer(
        uint256 _tokenIdSupply,
        address _newSeller
    ) external;

    /**
     * @notice Set the general cancelOrFault period, should be used sparingly as it has significant consequences. Here done simply for demo purposes.
     * @param _cancelFaultPeriod   the new value for cancelOrFault period (in number of seconds)
     */
    function setCancelFaultPeriod(uint256 _cancelFaultPeriod) external;

    /**
     * @notice Set the address of the Boson Router contract
     * @param _bosonRouterAddress   The address of the BR contract
     */
    function setBosonRouterAddress(address _bosonRouterAddress) external;

    /**
     * @notice Set the address of the Cashier contract
     * @param _cashierAddress   The address of the Cashier contract
     */
    function setCashierAddress(address _cashierAddress) external;

    /**
     * @notice Set the address of the Vouchers token contract, an ERC721 contract
     * @param _voucherTokenAddress   The address of the Vouchers token contract
     */
    function setVoucherTokenAddress(address _voucherTokenAddress) external;

    /**
     * @notice Set the address of the Voucher Sets token contract, an ERC1155 contract
     * @param _voucherSetTokenAddress   The address of the Voucher Sets token contract
     */
    function setVoucherSetTokenAddress(address _voucherSetTokenAddress)
        external;

    /**
     * @notice Set the general complain period, should be used sparingly as it has significant consequences. Here done simply for demo purposes.
     * @param _complainPeriod   the new value for complain period (in number of seconds)
     */
    function setComplainPeriod(uint256 _complainPeriod) external;

    /**
     * @notice Get the promise ID at specific index
     * @param _idx  Index in the array of promise keys
     * @return      Promise ID
     */
    function getPromiseKey(uint256 _idx) external view returns (bytes32);

    /**
     * @notice Get the address of the token where the price for the supply is held
     * @param _tokenIdSupply   ID of the voucher token
     * @return                  Address of the token
     */
    function getVoucherPriceToken(uint256 _tokenIdSupply)
        external
        view
        returns (address);

    /**
     * @notice Get the address of the token where the deposits for the supply are held
     * @param _tokenIdSupply   ID of the voucher token
     * @return                  Address of the token
     */
    function getVoucherDepositToken(uint256 _tokenIdSupply)
        external
        view
        returns (address);

    /**
     * @notice Get Buyer costs required to make an order for a supply token
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns a tuple (Payment amount, Buyer's deposit)
     */
    function getBuyerOrderCosts(uint256 _tokenIdSupply)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Get Seller deposit
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns sellers deposit
     */
    function getSellerDeposit(uint256 _tokenIdSupply)
        external
        view
        returns (uint256);

    /**
     * @notice Get the promise ID from a voucher token
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  ID of the promise
     */
    function getIdSupplyFromVoucher(uint256 _tokenIdVoucher)
        external
        pure
        returns (uint256);

    /**
     * @notice Get the promise ID from a voucher token
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  ID of the promise
     */
    function getPromiseIdFromVoucherId(uint256 _tokenIdVoucher)
        external
        view
        returns (bytes32);

    /**
     * @notice Get all necessary funds for a supply token
     * @param _tokenIdSupply   ID of the supply token
     * @return                  returns a tuple (Payment amount, Seller's deposit, Buyer's deposit)
     */
    function getOrderCosts(uint256 _tokenIdSupply)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Get the remaining quantity left in supply of tokens (e.g ERC-721 left in ERC-1155) of an account
     * @param _tokenSupplyId  Token supply ID
     * @param _owner    holder of the Token Supply
     * @return          remaining quantity
     */
    function getRemQtyForSupply(uint256 _tokenSupplyId, address _owner)
        external
        view
        returns (uint256);

    /**
     * @notice Get the payment method for a particular _tokenIdSupply
     * @param _tokenIdSupply   ID of the voucher supply token
     * @return                  payment method
     */
    function getVoucherPaymentMethod(uint256 _tokenIdSupply)
        external
        view
        returns (PaymentMethod);

    /**
     * @notice Get the current status of a voucher
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  Status of the voucher (via enum)
     */
    function getVoucherStatus(uint256 _tokenIdVoucher)
        external
        view
        returns (
            uint8,
            bool,
            bool,
            uint256,
            uint256
        );

    /**
     * @notice Get the holder of a supply
     * @param _tokenIdSupply    _tokenIdSupply ID of the order (aka VoucherSet) which is mapped to the corresponding Promise.
     * @return                  Address of the holder
     */
    function getSupplyHolder(uint256 _tokenIdSupply)
        external
        view
        returns (address);

    /**
     * @notice Get the holder of a voucher
     * @param _tokenIdVoucher   ID of the voucher token
     * @return                  Address of the holder
     */
    function getVoucherHolder(uint256 _tokenIdVoucher)
        external
        view
        returns (address);

    /**
     * @notice Checks whether a voucher is in valid period for redemption (between start date and end date)
     * @param _tokenIdVoucher ID of the voucher token
     */
    function isInValidityPeriod(uint256 _tokenIdVoucher)
        external
        view
        returns (bool);

    /**
     * @notice Checks whether a voucher is in valid state to be transferred. If either payments or deposits are released, voucher could not be transferred
     * @param _tokenIdVoucher ID of the voucher token
     */
    function isVoucherTransferable(uint256 _tokenIdVoucher)
        external
        view
        returns (bool);

    /**
     * @notice Get address of the Boson Router contract to which this contract points
     * @return Address of the Boson Router contract
     */
    function getBosonRouterAddress() external view returns (address);

    /**
     * @notice Get address of the Cashier contract to which this contract points
     * @return Address of the Cashier contract
     */
    function getCashierAddress() external view returns (address);

    /**
     * @notice Get the token nonce for a seller
     * @param _seller Address of the seller
     * @return The seller's
     */
    function getTokenNonce(address _seller) external view returns (uint256);

    /**
     * @notice Get the current type Id
     * @return type Id
     */
    function getTypeId() external view returns (uint256);

    /**
     * @notice Get the complain period
     * @return complain period
     */
    function getComplainPeriod() external view returns (uint256);

    /**
     * @notice Get the cancel or fault period
     * @return cancel or fault period
     */
    function getCancelFaultPeriod() external view returns (uint256);

    /**
     * @notice Get promise data not retrieved by other accessor functions
     * @param _promiseKey   ID of the promise
     * @return promise data not returned by other accessor methods
     */
    function getPromiseData(bytes32 _promiseKey)
        external
        view
        returns (
            bytes32,
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @notice Get the promise ID from a voucher set
     * @param _tokenIdSupply   ID of the voucher token
     * @return                  ID of the promise
     */
    function getPromiseIdFromSupplyId(uint256 _tokenIdSupply)
        external
        view
        returns (bytes32);

    /**
     * @notice Get the address of the Vouchers token contract, an ERC721 contract
     * @return Address of Vouchers contract
     */
    function getVoucherTokenAddress() external view returns (address);

    /**
     * @notice Get the address of the VoucherSets token contract, an ERC155 contract
     * @return Address of VoucherSets contract
     */
    function getVoucherSetTokenAddress() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20WithPermit is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // solhint-disable-next-line func-name-mixedcase
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address _owner) external view returns (uint256);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

interface ITokenRegistry {
    /**
     * @notice Set new limit for a token. It's used while seller tries to create a voucher. The limit is determined by a voucher set. Voucher price * quantity, seller deposit * quantity, buyer deposit * qty must be below the limit.
     * @param _tokenAddress Address of the token which will be updated.
     * @param _newLimit New limit which will be set. It must comply to the decimals of the token, so the limit is set in the correct decimals.
     */
    function setTokenLimit(address _tokenAddress, uint256 _newLimit) external;

    /**
     * @notice Get the maximum allowed token limit for the specified Token.
     * @param _tokenAddress Address of the token which will be update.
     * @return The max limit for this token
     */
    function getTokenLimit(address _tokenAddress)
        external
        view
        returns (uint256);

    /**
     * @notice Set new limit for ETH. It's used while seller tries to create a voucher. The limit is determined by a voucher set. Voucher price * quantity, seller deposit * quantity, buyer deposit * qty must be below the limit.
     * @param _newLimit New limit which will be set.
     */
    function setETHLimit(uint256 _newLimit) external;

    /**
     * @notice Get the maximum allowed ETH limit to set as price of voucher, buyer deposit or seller deposit.
     * @return The max ETH limit
     */
    function getETHLimit() external view returns (uint256);

    /**
     * @notice Set the address of the wrapper contract for the token. The wrapper is used to, for instance, allow the Boson Protocol functions that use permit functionality to work in a uniform way.
     * @param _tokenAddress Address of the token which will be updated.
     * @param _wrapperAddress Address of the wrapper contract
     */
    function setTokenWrapperAddress(
        address _tokenAddress,
        address _wrapperAddress
    ) external;

    /**
     * @notice Get the address of the token wrapper contract for the specified token
     * @param _tokenAddress Address of the token which will be updated.
     * @return Address of the token wrapper contract
     */
    function getTokenWrapperAddress(address _tokenAddress)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

import "./../UsingHelpers.sol";

interface IBosonRouter {
    function pause() external;

    function unpause() external;

    /**
     * @notice Issuer/Seller offers promises as supply tokens and needs to escrow the deposit
        @param _metadata metadata which is required for creation of a voucher
        Metadata array is used as in some scenarios we need several more params, as we need to recover 
        owner address in order to permit the contract to transfer funds in his behalf. 
        Since the params get too many, we end up in situation that the stack is too deep.
        
        uint256 _validFrom = _metadata[0];
        uint256 _validTo = _metadata[1];
        uint256 _price = _metadata[2];
        uint256 _depositSe = _metadata[3];
        uint256 _depositBu = _metadata[4];
        uint256 _quantity = _metadata[5];
     */
    function requestCreateOrderETHETH(uint256[] calldata _metadata)
        external
        payable;

    function requestCreateOrderETHETHConditional(
        uint256[] calldata _metadata,
        address _gateAddress,
        uint256 _nftTokenId
    ) external payable;

    function requestCreateOrderTKNTKNWithPermit(
        address _tokenPriceAddress,
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata
    ) external;

    function requestCreateOrderTKNTKNWithPermitConditional(
        address _tokenPriceAddress,
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata,
        address _gateAddress,
        uint256 _nftTokenId
    ) external;

    function requestCreateOrderETHTKNWithPermit(
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata
    ) external;

    function requestCreateOrderETHTKNWithPermitConditional(
        address _tokenDepositAddress,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256[] calldata _metadata,
        address _gateAddress,
        uint256 _nftTokenId
    ) external;

    function requestCreateOrderTKNETH(
        address _tokenPriceAddress,
        uint256[] calldata _metadata
    ) external payable;

    function requestCreateOrderTKNETHConditional(
        address _tokenPriceAddress,
        uint256[] calldata _metadata,
        address _gateAddress,
        uint256 _nftTokenId
    ) external payable;

    /**
     * @notice Consumer requests/buys a voucher by filling an order and receiving a Voucher Token in return
     * @param _tokenIdSupply    ID of the supply token
     * @param _issuer           Address of the issuer of the supply token
     */
    function requestVoucherETHETH(uint256 _tokenIdSupply, address _issuer)
        external
        payable;

    function requestVoucherTKNTKNWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _vPrice,
        bytes32 _rPrice,
        bytes32 _sPrice, // tokenPrice
        uint8 _vDeposit,
        bytes32 _rDeposit,
        bytes32 _sDeposit // tokenDeposits
    ) external;

    function requestVoucherTKNTKNSameWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensSent,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function requestVoucherETHTKNWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensDeposit,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;

    function requestVoucherTKNETHWithPermit(
        uint256 _tokenIdSupply,
        address _issuer,
        uint256 _tokensPrice,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable;

    /**
     * @notice Seller burns the remaining supply and withdrawal of the locked deposits for them are being sent back.
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) which will be burned and deposits will be returned for
     */
    function requestCancelOrFaultVoucherSet(uint256 _tokenIdSupply) external;

    /**
     * @notice Redemption of the vouchers promise
     * @param _tokenIdVoucher   ID of the voucher
     */
    function redeem(uint256 _tokenIdVoucher) external;

    /**
     * @notice Refunding a voucher
     * @param _tokenIdVoucher   ID of the voucher
     */
    function refund(uint256 _tokenIdVoucher) external;

    /**
     * @notice Issue a complain for a voucher
     * @param _tokenIdVoucher   ID of the voucher
     */
    function complain(uint256 _tokenIdVoucher) external;

    /**
     * @notice Cancel/Fault transaction by the Seller, admitting to a fault or backing out of the deal
     * @param _tokenIdVoucher   ID of the voucher
     */
    function cancelOrFault(uint256 _tokenIdVoucher) external;

    /**
     * @notice Get the address of Cashier contract
     * @return Address of Cashier address
     */
    function getCashierAddress() external view returns (address);

    /**
     * @notice Get the address of Voucher Kernel contract
     * @return Address of Voucher Kernel contract
     */
    function getVoucherKernelAddress() external view returns (address);

    /**
     * @notice Get the address gate contract that handles conditional commit of certain voucher set
     * @param _tokenIdSupply    ID of the supply token
     * @return Address of the gate contract or zero address if there is no conditional commit
     */
    function getVoucherSetToGateContract(uint256 _tokenIdSupply)
        external
        view
        returns (address);

    function getTokenRegistryAddress() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

import "./../UsingHelpers.sol";

interface ICashier {
    /**
     * @notice Pause the Cashier && the Voucher Kernel contracts in case of emergency.
     * All functions related to creating new batch, requestVoucher or withdraw will be paused, hence cannot be executed.
     * There is special function for withdrawing funds if contract is paused.
     */
    function pause() external;

    /**
     * @notice Unpause the Cashier && the Voucher Kernel contracts.
     * All functions related to creating new batch, requestVoucher or withdraw will be unpaused.
     */
    function unpause() external;

    function canUnpause() external view returns (bool);

    /**
     * @notice Trigger withdrawals of what funds are releasable
     * The caller of this function triggers transfers to all involved entities (pool, issuer, token holder), also paying for gas.
     * @dev This function would be optimized a lot, here verbose for readability.
     * @param _tokenIdVoucher  ID of a voucher token (ERC-721) to try withdraw funds from
     */
    function withdraw(uint256 _tokenIdVoucher) external;

    /**
     * @notice External function for withdrawing deposits. Caller must be the seller of the goods, otherwise reverts.
     * @notice Seller triggers withdrawals of remaining deposits for a given supply, in case the voucher set is no longer in exchange.
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) which will be burned and deposits will be returned for
     * @param _burnedQty burned quantity that the deposits should be withdrawn for
     * @param _messageSender owner of the voucher set
     */
    function withdrawDepositsSe(
        uint256 _tokenIdSupply,
        uint256 _burnedQty,
        address payable _messageSender
    ) external;

    /**
     * @notice Get the amount in escrow of an address
     * @param _account  The address of an account to query
     * @return          The balance in escrow
     */
    function getEscrowAmount(address _account) external view returns (uint256);

    /**
     * @notice Update the amount in escrow of an address with the new value, based on VoucherSet/Voucher interaction
     * @param _account  The address of an account to query
     */
    function addEscrowAmount(address _account) external payable;

    /**
     * @notice Update the amount in escrowTokens of an address with the new value, based on VoucherSet/Voucher interaction
     * @param _token  The address of a token to query
     * @param _account  The address of an account to query
     * @param _newAmount  New amount to be set
     */
    function addEscrowTokensAmount(
        address _token,
        address _account,
        uint256 _newAmount
    ) external;

    /**
     * @notice Hook which will be triggered when a _tokenIdVoucher will be transferred. Escrow funds should be allocated to the new owner.
     * @param _from prev owner of the _tokenIdVoucher
     * @param _to next owner of the _tokenIdVoucher
     * @param _tokenIdVoucher _tokenIdVoucher that has been transferred
     */
    function onVoucherTransfer(
        address _from,
        address _to,
        uint256 _tokenIdVoucher
    ) external;

    /**
     * @notice After the transfer happens the _tokenSupplyId should be updated in the promise. Escrow funds for the deposits (If in ETH) should be allocated to the new owner as well.
     * @param _from prev owner of the _tokenSupplyId
     * @param _to next owner of the _tokenSupplyId
     * @param _tokenSupplyId _tokenSupplyId for transfer
     * @param _value qty which has been transferred
     */
    function onVoucherSetTransfer(
        address _from,
        address _to,
        uint256 _tokenSupplyId,
        uint256 _value
    ) external;

    /**
     * @notice Get the address of Voucher Kernel contract
     * @return Address of Voucher Kernel contract
     */
    function getVoucherKernelAddress() external view returns (address);

    /**
     * @notice Get the address of Boson Router contract
     * @return Address of Boson Router contract
     */
    function getBosonRouterAddress() external view returns (address);

    /**
     * @notice Get the address of the Vouchers contract, an ERC721 contract
     * @return Address of Vouchers contract
     */
    function getVoucherTokenAddress() external view returns (address);

    /**
     * @notice Get the address of the VoucherSets token contract, an ERC155 contract
     * @return Address of VoucherSets contract
     */
    function getVoucherSetTokenAddress() external view returns (address);

    /**
     * @notice Ensure whether or not contract has been set to disaster state
     * @return disasterState
     */
    function isDisasterStateSet() external view returns (bool);

    /**
     * @notice Get the amount in escrow of an address
     * @param _token  The address of a token to query
     * @param _account  The address of an account to query
     * @return          The balance in escrow
     */
    function getEscrowTokensAmount(address _token, address _account)
        external
        view
        returns (uint256);

    /**
     * @notice Set the address of the BR contract
     * @param _bosonRouterAddress   The address of the Cashier contract
     */
    function setBosonRouterAddress(address _bosonRouterAddress) external;

    /**
     * @notice Set the address of the VoucherKernel contract
     * @param _voucherKernelAddress   The address of the VoucherKernel contract
     */
    function setVoucherKernelAddress(address _voucherKernelAddress) external;

    /**
     * @notice Set the address of the Vouchers token contract, an ERC721 contract
     * @param _voucherTokenAddress   The address of the Vouchers token contract
     */
    function setVoucherTokenAddress(address _voucherTokenAddress) external;

    /**
     * @notice Set the address of the Voucher Sets token contract, an ERC1155 contract
     * @param _voucherSetTokenAddress   The address of the Voucher Sets token contract
     */
    function setVoucherSetTokenAddress(address _voucherSetTokenAddress)
        external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

interface IGate {
    event LogNonTransferableContractSet(
        address indexed _nonTransferableTokenContractAddress,
        address indexed _triggeredBy
    );
    event LogBosonRouterSet(
        address indexed _bosonRouter,
        address indexed _triggeredBy
    );
    event LogVoucherSetRegistered(
        uint256 indexed _tokenIdSupply,
        uint256 indexed _nftTokenId
    );
    event LogUserVoucherDeactivated(
        address indexed _user,
        uint256 indexed _tokenIdSupply
    );

    /**
     * @notice For a given _tokenIdSupply, it tells on which NFT it depends
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return quest NFT token ID
     */
    function getNftTokenId(uint256 _tokenIdSupply)
        external
        view
        returns (uint256);

    /**
     * @notice Sets the contract, where gate contract checks if quest NFT token exists
     * @param _nonTransferableTokenContractAddress address of a non-transferable token contract
     */
    function setNonTransferableTokenContract(
        address _nonTransferableTokenContractAddress
    ) external;

    /**
     * @notice Sets the Boson router contract address, from which deactivate is accepted
     * @param _bosonRouter address of a non-transferable token contract
     */
    function setBosonRouterAddress(address _bosonRouter) external;

    /**
     * @notice Registers connection between setID and tokenID
     * @param _tokenIdSupply an ID of a supply token (ERC-1155)
     * @param _nftTokenId an ID of a quest token
     */
    function registerVoucherSetId(uint256 _tokenIdSupply, uint256 _nftTokenId)
        external;

    /**
     * @notice Gets the contract address, where gate contract checks if quest NFT token exists
     * @return Address of contract that hold non transferable NFTs (quest NFTs)
     */
    function getNonTransferableTokenContract() external view returns (address);

    /**
     * @notice Checks if user possesses the required quest NFT token for given voucher set
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     * @return true if user possesses quest NFT token, and the token is not deactivated
     */
    function check(address _user, uint256 _tokenIdSupply)
        external
        view
        returns (bool);

    /**
     * @notice Stores information that certain user already claimed
     * @param _user user address
     * @param _tokenIdSupply an ID of a supply token (ERC-1155) [voucherSetID]
     */
    function deactivate(address _user, uint256 _tokenIdSupply) external;

    /**
     * @notice Pause register and deactivate
     */
    function pause() external;

    /**
     * @notice Unpause the contract and allows register and deactivate
     */
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.7.6;

interface ITokenWrapper {
    event LogTokenAddressChanged(
        address indexed _newWrapperAddress,
        address indexed _triggeredBy
    );

    event LogPermitCalledOnToken(
        address indexed _tokenAddress,
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    /**
     * @notice Provides a way to make calls to the permit function of tokens in a uniform way
     * @param _owner Address of the token owner who is approving tokens to be transferred by spender
     * @param _spender Address of the party who is transferring tokens on owner's behalf
     * @param _value Number of tokens to be transferred
     * @param _deadline Time after which this permission to transfer is no longer valid
     * @param _v Part of the owner's signatue
     * @param _r Part of the owner's signatue
     * @param _s Part of the owner's signatue
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    /**
     * @notice Set the address of the wrapper contract for the token. The wrapper is used to, for instance, allow the Boson Protocol functions that use permit functionality to work in a uniform way.
     * @param _tokenAddress Address of the token which will be updated.
     */
    function setTokenAddress(address _tokenAddress) external;

    /**
     * @notice Get the address of the token wrapped by this contract
     * @return Address of the token wrapper contract
     */
    function getTokenAddress() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

// Those are the payment methods we are using throughout the system.
// Depending on how to user choose to interact with it's funds we store the method, so we could distribute its tokens afterwise
enum PaymentMethod {
    ETHETH,
    ETHTKN,
    TKNETH,
    TKNTKN
}

enum VoucherState {FINAL, CANCEL_FAULT, COMPLAIN, EXPIRE, REFUND, REDEEM, COMMIT}
/*  Status of the voucher in 8 bits:
    [6:COMMITTED] [5:REDEEMED] [4:REFUNDED] [3:EXPIRED] [2:COMPLAINED] [1:CANCELORFAULT] [0:FINAL]
*/

uint8 constant ONE = 1;

struct VoucherDetails {
    uint256 tokenIdSupply;
    uint256 tokenIdVoucher;
    address issuer;
    address holder;
    uint256 price;
    uint256 depositSe;
    uint256 depositBu;
    uint256 price2pool;
    uint256 deposit2pool;
    uint256 price2issuer;
    uint256 deposit2issuer;
    uint256 price2holder;
    uint256 deposit2holder;
    PaymentMethod paymentMethod;
    VoucherStatus currStatus;
}

struct VoucherStatus {
    uint8 status;
    bool isPaymentReleased;
    bool isDepositsReleased;
    uint256 complainPeriodStart;
    uint256 cancelFaultPeriodStart;
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Committed state.
    * @param _status current status of a voucher.
    */
function isStateCommitted(uint8 _status) pure returns (bool) {
    return _status == determineStatus(0, VoucherState.COMMIT);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in RedemptionSigned state.
    * @param _status current status of a voucher.
    */
function isStateRedemptionSigned(uint8 _status)
    pure
    returns (bool)
{
    return _status == determineStatus(determineStatus(0, VoucherState.COMMIT), VoucherState.REDEEM);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Refunded state.
    * @param _status current status of a voucher.
    */
function isStateRefunded(uint8 _status) pure returns (bool) {
    return _status == determineStatus(determineStatus(0, VoucherState.COMMIT), VoucherState.REFUND);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks whether a voucher is in Expired state.
    * @param _status current status of a voucher.
    */
function isStateExpired(uint8 _status) pure returns (bool) {
    return _status == determineStatus(determineStatus(0, VoucherState.COMMIT), VoucherState.EXPIRE);
}

/**
    * @notice Based on its lifecycle, voucher can have many different statuses. Checks the current status a voucher is at.
    * @param _status current status of a voucher.
    * @param _idx status to compare.
    */
function isStatus(uint8 _status, VoucherState _idx) pure returns (bool) {
    return (_status >> uint8(_idx)) & ONE == 1;
}

/**
    * @notice Set voucher status.
    * @param _status previous status.
    * @param _changeIdx next status.
    */
function determineStatus(uint8 _status, VoucherState _changeIdx)
    pure
    returns (uint8)
{
    return _status | (ONE << uint8(_changeIdx));
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity 0.7.6;

import "../interfaces/IERC20WithPermit.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeERC20WithPermit
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20WithPermit for IERC20WithPermit;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20WithPermit {
    using Address for address;

    function safeTransferFrom(
        IERC20WithPermit _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        _callOptionalReturn(
            _token,
            abi.encodeWithSelector(
                _token.transferFrom.selector,
                _from,
                _to,
                _value
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param _token The token targeted by the call.
     * @param _data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20WithPermit _token, bytes memory _data)
        private
    {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(_token).functionCall(
            _data,
            "SafeERC20WithPermit: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20WithPermit: ERC20WithPermit operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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