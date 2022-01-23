/**
 *Submitted for verification at Etherscan.io on 2022-01-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity 0.8.7;

interface IFactory{
    event CampaignCreated(address indexed campaign, uint256 index);
    
    function owner() external  view returns (address);
	function token() external view returns (address);
    
	function recipients(uint256) external view returns(address);
    function allCampaignLength() external view returns(uint256);
    function allCampaigns(uint256) external view returns(address);
    function campaignApproved(address) external view returns(bool);
    function recipientApproved(address) external view returns(bool);
    function campaignToRecipient(address) external view returns(address);
    function recipientToCampaign(address, uint256) external view returns(address);

	function createRecipient(bytes32, bytes32, bytes32) external returns(bool);
    function createCampaign(uint256, uint256, uint256, bytes32, bytes32, bytes memory) external returns (address);
    
	function updateName(bytes32) external returns(bool);
	function updateWa(bytes32) external returns(bool);
	function updateLocation(bytes32) external returns(bool);

	function toggleApproveRecipient(address) external returns(bool);
	function toggleApproveCampaign(address) external returns(bool);
	function setToken(address) external returns(bool);
    function transferOwnership(address) external returns(bool);
}


pragma solidity 0.8.7;

contract Campaign {
	bytes32 public title;
	uint256 public goal;
	uint256 public startDate;
	uint256 public endDate;
	uint256 public pledged;
	bytes32 public desc;
	bytes public pict;
	address public immutable recipient;
	IFactory public factory;
	bool public initialized;
	address[] public donatur;

	struct Detail{
  		uint256 donaturIndex;
		uint256 dateTime;
  		uint256 amount;
        uint256 idr;
		uint256 index;
  	}

	struct Withdrawal{
		uint256 wAt;
		uint256 wAmount;
		uint256 wIdr;
	}
	
	bytes32[] public invoices;
	bytes32[] public receipt;
	mapping (bytes32 => Detail) public invoiceToDetail;
	mapping (bytes32 => Withdrawal) public receiptToDetail;
	mapping(address => bytes32[]) public donaturToInvoice;
	 

	event UpdateDesc(address indexed campaign, bytes32 desc);

	modifier onlyFactory {
		require(msg.sender == address(factory), "Not factory");
		_;
	}

	modifier onlyRecipient {
		require(msg.sender == recipient, "Not recipient");
		_;
	}

	modifier isApproved {
		require(factory.campaignApproved(address(this)), "Not approved");
		
		_;
	}

	constructor() {
		factory = IFactory(msg.sender);
		recipient = tx.origin;
	}

	function initialize(	
		uint256 _goal,
		uint256 _startDate,
		uint256 _endDate,
		bytes32 _title,
		bytes32 _desc,
		bytes memory _pict
	) external onlyFactory returns(bool){
		require(!initialized, "Initialized");
		title = _title;
		goal = _goal;
		startDate = _startDate;
		endDate = _endDate;
		desc = _desc;
		pict = _pict;

		initialized = true;

		return true;
	}

	function donate(uint256 _amount, uint256 _idr) external isApproved returns (bool){
		require(block.timestamp >= startDate && block.timestamp <= endDate, "Period donate is over");
		require(pledged <= goal, "Donate completed");
		
		TransferHelper.safeTransferFrom(factory.token(), msg.sender, address(this), _amount);
        
		uint256 donaturIndex = setDonatur(msg.sender);
		uint256 dateTime = block.timestamp;
		bytes32 invoiceId = bytes32(abi.encodePacked("Invoice-", invoiceLength()+1)); 
		
		invoices.push(invoiceId);
		invoiceToDetail[invoiceId] = Detail(donaturIndex, dateTime, _amount, _idr, invoiceLength()-1);
		donaturToInvoice[msg.sender].push(invoiceId);

		pledged += _amount;

		return true;
	}

	function withdraw(uint256 _amount, uint256 _idr, bytes32 _desc) external onlyRecipient isApproved returns(bool){
		require(block.timestamp >= startDate && pledged > 0 && _amount <= pledged, "Not now");

		bytes32 withdrawalId = bytes32(abi.encodePacked("Receipt-", receiptLength()+1));
		receipt.push(withdrawalId);
		receiptToDetail[withdrawalId] = Withdrawal(block.timestamp, _amount, _idr);

		require(updateDesc(_desc), "Update failed");

		TransferHelper.safeTransfer(factory.token(), msg.sender, _amount);

		return true;

	}

	function updateDesc(bytes32 _desc) public onlyRecipient returns(bool){
		desc = _desc;

		emit UpdateDesc(address(this), desc);
		return true;
	}

	function setDonatur(address _donatur) private returns(uint256){
		if(donaturToInvoiceLength(_donatur) == 0){
			donatur.push(_donatur);
		}

		return donaturLength() - 1;
	}


	function donaturLength() public view returns(uint256){
		return donatur.length;
	}

	function receiptLength() public view returns(uint256){
		return receipt.length;
	}

	function donaturToInvoiceLength(address _donatur) public view returns(uint256){
		return donaturToInvoice[_donatur].length;
	}

	function invoiceLength() public view returns(uint256){
		return invoices.length;
	}

}