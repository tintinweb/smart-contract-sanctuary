contract EthereumButton {
    address private owner;
    address private lastPresser;
    uint256 private targetBlock;
    uint256 private pressCount;
    bool private started = false;

    event Pressed(address _presser, uint256 _timestamp);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhenStarted() {
        require(started == true);
        _;
    }

    modifier onlyWhenPaused() {
        require(started == false);
        _;
    }
    
    function EthereumButton() public {
        owner = msg.sender;
    }
    
    function start() public onlyOwner onlyWhenPaused {
        started = true;
        targetBlock = block.number + 240;
        pressCount = 0;
        lastPresser = 0x0;
    }

    function() public payable {
        revert();
    }   

    function pressButton() public onlyWhenStarted payable {
        require(msg.value == 10000000000000000 && block.number <= targetBlock);

        lastPresser = msg.sender;
        targetBlock = targetBlock + 240;
        pressCount++;

        Pressed(msg.sender, now);
    }

    function getPressCount() public view returns(uint256) {
        return pressCount;
    }

    function getTargetBlock() public view returns(uint256) {
        return targetBlock;
    }

    function getLastPresser() public view returns(address) {
        return lastPresser;
    }
    
    function claimPrize() public onlyWhenStarted {
        require(block.number > targetBlock && (msg.sender == lastPresser || msg.sender == owner));

        // In case of nobody pressed it, the owner can call this to set started to false
        if (pressCount == 0) {
            started = false;
            return;
        }

        uint256 amount = pressCount * 9500000000000000;
        
        lastPresser.transfer(amount);

        started = false;
    }

    function depositEther() public payable onlyOwner { } 

    function kill() public onlyOwner onlyWhenPaused {
        selfdestruct(owner);
    }

    function withdrawBalance() public onlyOwner onlyWhenPaused {
        owner.transfer(this.balance);
    }
}