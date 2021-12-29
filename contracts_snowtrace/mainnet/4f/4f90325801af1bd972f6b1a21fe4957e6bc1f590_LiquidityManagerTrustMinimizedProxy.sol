/**
 *Submitted for verification at snowtrace.io on 2021-12-29
*/

pragma solidity >=0.7.6 <0.8.0;

// EIP-3561 trust minimized proxy implementation https://github.com/ethereum/EIPs/blob/master/EIPS/eip-3561.md

contract LiquidityManagerTrustMinimizedProxy{ // THE CODE FITS ON THE SCREEN UNBELIAVABLE LETS STOP ENDLESS SCROLLING UP AND DOWN
	event Upgraded(address indexed toLogic);
	event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
	event NextLogicDefined(address indexed nextLogic, uint earliestArrivalBlock);
	event ProposingUpgradesRestrictedUntil(uint block, uint nextProposedLogicEarliestArrival);
	event NextLogicCanceled();
	event TrustRemoved();

	bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
	bytes32 internal constant LOGIC_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
	bytes32 internal constant NEXT_LOGIC_SLOT = 0xb182d207b11df9fb38eec1e3fe4966cf344774ba58fb0e9d88ea35ad46f3601e;
	bytes32 internal constant NEXT_LOGIC_BLOCK_SLOT = 0x96de003e85302815fe026bddb9630a50a1d4dc51c5c355def172204c3fd1c733;
	bytes32 internal constant PROPOSE_BLOCK_SLOT = 0xbc9d35b69e82e85049be70f91154051f5e20e574471195334bde02d1a9974c90;
	bytes32 internal constant TRUST_MINIMIZED_SLOT = 0xa0ea182b754772c4f5848349cff27d3431643ba25790e0c61a8e4bdf4cec9201;

	constructor() payable {
		require(ADMIN_SLOT == bytes32(uint256(keccak256('eip1967.proxy.admin')) - 1) && LOGIC_SLOT==bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1) // this require is simply against human error, can be removed if you know what you are doing
		&& NEXT_LOGIC_SLOT == bytes32(uint256(keccak256('eip1984.proxy.nextLogic')) - 1) && NEXT_LOGIC_BLOCK_SLOT == bytes32(uint256(keccak256('eip1984.proxy.nextLogicBlock')) - 1)
		&& PROPOSE_BLOCK_SLOT == bytes32(uint256(keccak256('eip1984.proxy.proposeBlock')) - 1)/* && DEADLINE_SLOT == bytes32(uint256(keccak256('eip1984.proxy.deadline')) - 1)*/
		&& TRUST_MINIMIZED_SLOT == bytes32(uint256(keccak256('eip1984.proxy.trustMinimized')) - 1));
		_setAdmin(msg.sender);
	}

	modifier ifAdmin() {if (msg.sender == _admin()) {_;} else {_fallback();}}
	function _logic() internal view returns (address logic) {assembly { logic := sload(LOGIC_SLOT) }}
	function _nextLogic() internal view returns (address nextLogic) {assembly { nextLogic := sload(NEXT_LOGIC_SLOT) }}
	function _proposeBlock() internal view returns (uint bl) {assembly { bl := sload(PROPOSE_BLOCK_SLOT) }}
	function _nextLogicBlock() internal view returns (uint bl) {assembly { bl := sload(NEXT_LOGIC_BLOCK_SLOT) }}
	function _trustMinimized() internal view returns (uint tm) {assembly { tm := sload(TRUST_MINIMIZED_SLOT) }}
	function _admin() internal view returns (address adm) {assembly { adm := sload(ADMIN_SLOT) }}
	function _setAdmin(address newAdm) internal {assembly {sstore(ADMIN_SLOT, newAdm)}}
	function changeAdmin(address newAdm) external ifAdmin {emit AdminChanged(_admin(), newAdm);_setAdmin(newAdm);}
	function upgrade() external ifAdmin {require(block.number>=_nextLogicBlock(),"too soon");address logic;assembly {logic := sload(NEXT_LOGIC_SLOT) sstore(LOGIC_SLOT,logic)}emit Upgraded(logic);}
	fallback () external payable {_fallback();}
	receive () external payable {_fallback();}
	function _fallback() internal {require(msg.sender != _admin());_delegate(_logic());}
	function cancelUpgrade() external ifAdmin {address logic; assembly {logic := sload(LOGIC_SLOT)sstore(NEXT_LOGIC_SLOT, logic)}emit NextLogicCanceled();}
	function prolongLock(uint b) external ifAdmin {require(b > _proposeBlock(),"get maxxed"); assembly {sstore(PROPOSE_BLOCK_SLOT,b)} emit ProposingUpgradesRestrictedUntil(b,b+1296000);}
	function removeTrust() external ifAdmin {assembly{ sstore(TRUST_MINIMIZED_SLOT, 1) }emit TrustRemoved();} // before this called acts like a normal eip 1967 transparent proxy. after the deployer confirms everything is deployed correctly must be called
	function _updateBlockSlot() internal {uint nlb = block.number + 1296000; assembly {sstore(NEXT_LOGIC_BLOCK_SLOT,nlb)}}
	function _setNextLogic(address nl) internal {require(block.number >= _proposeBlock(),"too soon");_updateBlockSlot();assembly { sstore(NEXT_LOGIC_SLOT, nl)}emit NextLogicDefined(nl,block.number + 1296000);}

	function proposeToAndCall(address newLogic, bytes calldata data) payable external ifAdmin {
		if (_trustMinimized() == 0) {_updateBlockSlot();assembly {sstore(LOGIC_SLOT,newLogic)}emit Upgraded(newLogic);}	else{ _setNextLogic(newLogic);}
		(bool success,) = newLogic.delegatecall(data);require(success,"failed to call");
	}

    function viewSlots() external ifAdmin returns(address logic, address nextLogic, uint proposeBlock, uint nextLogicBlock, uint trustMinimized, address admin) {
        return (_logic(),_nextLogic(),_proposeBlock(),_nextLogicBlock(),_trustMinimized(),_admin());
    }

	function _delegate(address logic_) internal {
		assembly {
			calldatacopy(0, 0, calldatasize())
			let result := delegatecall(gas(), logic_, 0, calldatasize(), 0, 0)
			returndatacopy(0, 0, returndatasize())
			switch result
			case 0 { revert(0, returndatasize()) }
			default { return(0, returndatasize()) }
		}
	}
}