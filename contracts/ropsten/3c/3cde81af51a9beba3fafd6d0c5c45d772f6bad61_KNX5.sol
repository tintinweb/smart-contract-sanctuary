pragma solidity ^0.4.25;

contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool);
  function transferFrom(address from, address to, uint tokens) public returns (bool);
  function balanceOf(address tokenOwner) public view returns (uint256);
  function allowance(address tokenOwner, address spender) public view returns (uint);
}

contract KNX5{
    address public admin;
    uint256 win;
    uint256 _seed = now;
    event BetResult(
    address from,
    uint256 betvalue,
    bool win,
    uint256 wonamount
    );
    
    event LuckyDrop(
    address from,
    uint256 betvalue,
    string congratulation
    );
    
    event Shake(
    address from,
    bytes32 make_chaos
    );
    
    constructor() public{
        admin = 0x1E1C1Fa8Ee39151ba082daE2F24E906882F4681C;
    }
    
    function random() private view returns (uint8) {
        return uint8(uint256(keccak256(block.timestamp, block.difficulty, _seed))%100); // random 0-99
    }
    
    function bet() public payable {
        require(msg.value >= 1);
        require(ERC20Interface(0x82d987E8c27DB4a75Dd22D770335a5E5435252CD).balanceOf(address(msg.sender)) >= 50);
        ERC20Interface(0x82d987E8c27DB4a75Dd22D770335a5E5435252CD).transferFrom(msg.sender, address(this), 50);
        win = msg.value*97/20;
        uint8 _random = random();

        if (_random +20 >= 100) {
            if(win < address(this).balance) {
                msg.sender.transfer(win);
                emit BetResult(msg.sender, msg.value, true, win);
            } else {
                msg.sender.transfer(address(this).balance);
                emit BetResult(msg.sender, msg.value, true, address(this).balance);
            }
        } else {
            emit BetResult(msg.sender, msg.value, false, 0x0);
        }
    }
    

    modifier onlyAdmin() {
        // Ensure the participant awarding the ether is the admin
        require(msg.sender == admin);
        _;
    }
    
    function withdrawEth(address to, uint256 balance) external onlyAdmin {
        if (balance == uint256(0x0)) {
            to.transfer(address(this).balance);
        } else {
        to.transfer(balance);
        }
    }
    
    function withdrawToken(address contractAddress, address to, uint256 balance) external onlyAdmin {
        ERC20Interface erc20 = ERC20Interface(contractAddress);
        if (balance == uint256(0x0)){
            erc20.transfer(to, erc20.balanceOf(address(this)));
        } else {
            erc20.transfer(to, balance);
        }
    }
    
    function shake(uint256 choose_a_number_to_chaos_the_algo) public {
        _seed = uint256(keccak256(choose_a_number_to_chaos_the_algo));
        emit Shake(msg.sender, "You changed the algo");
    }
    
    function () public payable {
        require(msg.value > 0 ether);
    }
}