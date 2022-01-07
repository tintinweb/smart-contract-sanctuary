// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {NonReceivableInitializedProxy} from "./NonReceivableInitializedProxy.sol";
import {PartyBuy} from "./PartyBuy.sol";
import {Structs} from "./Structs.sol";

/**
 * @title PartyBuy Factory
 * @author Anna Carroll
 */
contract PartyBuyFactory {
    //======== Events ========

    event PartyBuyDeployed(
        address partyProxy,
        address creator,
        address nftContract,
        uint256 tokenId,
        uint256 maxPrice,
        uint256 secondsToTimeout,
        address splitRecipient,
        uint256 splitBasisPoints,
        address gatedToken,
        uint256 gatedTokenAmount,
        string name,
        string symbol
    );

    //======== Immutable storage =========

    address public immutable logic;
    address public immutable partyDAOMultisig;
    address public immutable tokenVaultFactory;
    address public immutable weth;

    //======== Mutable storage =========

    // PartyBid proxy => block number deployed at
    mapping(address => uint256) public deployedAt;

    //======== Constructor =========

    constructor(
        address _partyDAOMultisig,
        address _tokenVaultFactory,
        address _weth,
        address _allowList
    ) {
        partyDAOMultisig = _partyDAOMultisig;
        tokenVaultFactory = _tokenVaultFactory;
        weth = _weth;
        // deploy logic contract
        PartyBuy _logicContract = new PartyBuy(_partyDAOMultisig, _tokenVaultFactory, _weth, _allowList);
        // store logic contract address
        logic = address(_logicContract);
    }

    //======== Deploy function =========

    function startParty(
        address _nftContract,
        uint256 _tokenId,
        uint256 _maxPrice,
        uint256 _secondsToTimeout,
        Structs.AddressAndAmount calldata _split,
        Structs.AddressAndAmount calldata _tokenGate,
        string memory _name,
        string memory _symbol
    ) external returns (address partyBuyProxy) {
        bytes memory _initializationCalldata =
            abi.encodeWithSelector(
            PartyBuy.initialize.selector,
            _nftContract,
            _tokenId,
            _maxPrice,
            _secondsToTimeout,
            _split,
            _tokenGate,
            _name,
            _symbol
        );

        partyBuyProxy = address(
            new NonReceivableInitializedProxy(
                logic,
                _initializationCalldata
            )
        );

        deployedAt[partyBuyProxy] = block.number;

        emit PartyBuyDeployed(
            partyBuyProxy,
            msg.sender,
            _nftContract,
            _tokenId,
            _maxPrice,
            _secondsToTimeout,
            _split.addr,
            _split.amount,
            _tokenGate.addr,
            _tokenGate.amount,
            _name,
            _symbol
        );
    }
}