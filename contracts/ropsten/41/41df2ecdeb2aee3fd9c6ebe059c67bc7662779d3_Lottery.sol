pragma solidity 0.4.24;

contract Lottery
{
    address   public manager;
    address[] public players;
    
    constructor() public
    {
        manager = msg.sender;
    }
    
    /* payable: khi goi ham nay thi phai chuyen tien vao truoc */
    function enter() public payable
    {
        require(msg.value == 0.1 ether);
        
        players.push(msg.sender);
    }
    
    /* view neu khong de thi cung tu hieu la view */
    /* view de thong bao tat ca mn khong duoc thay doi data trong smartcontract */
    function random() private view returns (uint)
    {
        return uint(keccak256(block.difficulty, now, players));
    }
    
    function pickWinner() public onlyManagerCanCall returns (address)
    {
        uint wIndex = random() % players.length;
        players[wIndex].transfer(address(this).balance);
        
        return players[wIndex];
    }
    
    modifier onlyManagerCanCall()
    {
        require(msg.sender == manager);
        _;
    }
    
}