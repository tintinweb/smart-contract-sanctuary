/**
 *Submitted for verification at polygonscan.com on 2021-12-23
*/

// File: contracts/BoleroArtist.sol



pragma solidity ^0.8.10;

interface IBoleroDeployer {
    function management() external view returns (address);
    function rewards() external view returns (address);
}

contract BoleroArtist {
    uint256 public constant MAXIMUM_PERCENT = 4750;
    address public bolero = address(0);
    address public artist = address(0);
    address public artistPayment = address(0);
    address public pendingArtist = address(0);
    bool public isWithPaymentSplitter = false;

    string public name;
    string public symbol;
    string public url;

	modifier onlyArtist() {
		require(msg.sender == artist, "!authorized");
		_;
	}
	modifier onlyBoleroOrManagement() {
		require(address(msg.sender) == bolero || address(msg.sender) == IBoleroDeployer(bolero).management(), "!authorized");
		_;
	}

    event SetArtistAddress(address newAddress);
    event SetPendingArtistAddress(address newAddress);

    constructor(
        address boleroAddress,
        address artistAddress,
        address artistPaymentAddress,
        string memory artistName,
        string memory artistSymbol,
        string memory artistURL,
        bool usePaymentSplitter
    ) {
        bolero = address(boleroAddress);
        artist = address(artistAddress);
        artistPayment = address(artistPaymentAddress);
        name = artistName;
        symbol = artistSymbol;
        url = artistURL;
        isWithPaymentSplitter = usePaymentSplitter;
    }

    /*******************************************************************************
    **	@notice
    **		Change the address of the artist. This address is used to get the fees.
    **      This set the pendingAddress and not the actual one. It
    **      must be confirmed by Bolero.
    **      Can only be called by the artist itself.
    **	@param _pendingArtist: the new address
    *******************************************************************************/
    function setPendingArtistAddress(address _pendingArtist) public onlyArtist() {
        require (_pendingArtist != address(0), "invalid address");

        pendingArtist = _pendingArtist;
        emit SetPendingArtistAddress(_pendingArtist);
    }

    /*******************************************************************************
    **	@notice
    **		Change the address of the artist. This use the pendingArtistAddress to
    **      set the artistAddress to it
    **      Can only be called by the BoleroContract.
    *******************************************************************************/
    function setArtistAddress() public onlyBoleroOrManagement() {
        require (pendingArtist != address(0), "invalid address");
        artist = pendingArtist;
        pendingArtist = address(0);
        emit SetArtistAddress(pendingArtist);
        emit SetPendingArtistAddress(address(0));
    }

    /*******************************************************************************
    **	@notice
    **		Change the payment address of the artist. This address is used to get
    **      the fees.
    **	@param _artist: the new address
    **  @param _isPaymentSplitter: if this address a paymentSplitter contract
    *******************************************************************************/
    function setArtistPayment(address _artistPayment, bool _isPaymentSplitter) public onlyBoleroOrManagement() {
        require (_artistPayment != address(0), "invalid address");
        artistPayment = _artistPayment;
        isWithPaymentSplitter = _isPaymentSplitter;
    }
}