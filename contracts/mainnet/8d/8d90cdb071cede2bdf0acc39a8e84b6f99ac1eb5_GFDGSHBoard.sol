pragma solidity 0.4.24;

contract GFDGSHBoard {
    
    // x => y => color
    mapping(uint256=>mapping(uint256=>uint256)) public canvas;
    uint256 ownerBalance;
    
    uint256 pixelRate;
    address owner;
    constructor() public {
        pixelRate = 100;
        owner = msg.sender;
        ownerBalance = 0;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function setPixelRate(uint256 _pixelRate) onlyOwner public {
        pixelRate = _pixelRate;
    }
    function pixelPrice(uint256 x, uint256 y) public view returns (uint256) {
        // 500k x 500k canvas
        require(x < 500000);
        require(y < 500000);
        uint256 pp = 0.0001 ether;
        if(x>100 && y>100) {
            pp = 0.00005 ether;
        }
        if(x>200 && y>200) {
            pp = 0.000025 ether;
        }
        if(x>400 && y>400) {
            pp = 0.0000125 ether;
        }
        if(x>800 && y>800) {
            pp = 0.00000625 ether;
        }
        if(x>1600 && y>1600) {
            pp = 0.000003125 ether;
        }
        if(x>3200 && y>3200) {
            pp = 0.00000155 ether;
        }
        if(x>6400 && y>6400) {
            pp = 0.0000007 ether;
        }
        if(x>12800 && y>12800) {
            pp = 0.00000035 ether;
        }
        if(x>25600 && y>25600) {
            pp = 0.000000125 ether;
        }
        if(x>51200 && y>51200) {
            pp = 0.0000000625 ether;
        }
        if(x>100000 && y>100000) {
            pp = 0.00000003125 ether;
        }
        if(x>200000 && y>200000) {
            pp = 0.00000001 ether;
        }
        if(x>400000 && y>400000) {
            pp = 0.000000001 ether;
        }
        return pp * pixelRate;
    }
    function priceForRect(uint256 left, uint256 right, uint256 top, uint256 bottom) public view returns (uint256) {
        require(top < bottom);
        require(right > left);
        uint256 price = 0;
        price += pixelPrice(left, top);
        price += pixelPrice(right, top);
        price += pixelPrice(left, bottom);
        price += pixelPrice(right, bottom);
        price /= 4;
        uint256 pixelCount = (right - left) * (bottom - top);
        return price * pixelCount;
    }
    function purchasePixel(uint256 x, uint256 y, uint256 color) public payable {
        require(color < 16777216);
        uint256 pp = pixelPrice(x, y);
        require(msg.value >= pp);
        canvas[x][y] = color;
        ownerBalance += msg.value;
    }
    function applyPixelChange(uint256 left, uint256 right, uint256 top, uint256 bottom, uint256[] colors) internal {
        uint256 colorIndex = 0;
        for(uint256 x = left; x < right; x++) {
            for (uint256 y = top; y < bottom; y++) {
                uint256 color = colors[colorIndex];
                require(color < 16777216);
                canvas[x][y] = color;
                colorIndex++;
            }
        }
    }
    function purchaseRect(uint256 left, uint256 right, uint256 top, uint256 bottom, uint256[] colors) payable public {
        uint256 pp = priceForRect(left, right, top, bottom);
        uint256 senderBal = balances[msg.sender];
        require((msg.value == pp) || senderBal >= pp || senderBal + msg.value >= pp);
        require(top < bottom);
        require(right > left);
        if(msg.value == pp) {
            // Paid for in message
            applyPixelChange(left, right, top, bottom, colors);
        }
        else if(msg.value != 0) {
            // Paid partially in message
            uint256 deductFromBal = pp - msg.value;
            require(balances[msg.sender] >= deductFromBal);
            balances[msg.sender] -= deductFromBal;
            applyPixelChange(left, right, top, bottom, colors);
        }
        else if(msg.value == 0) {
            // Paid fully from balance
            require(balances[msg.sender] >= pp);
            applyPixelChange(left, right, top, bottom, colors);
        }
        else {
            revert();
        }
    }
    mapping(address=>uint256) balances;
    function deposit() payable public {
        balances[msg.sender] += msg.value;
    }
    function() payable public {
        balances[msg.sender] += msg.value;
    }
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        require(balance >= 0);
        msg.sender.transfer(balance);
    }
    function adminWithdraw() public onlyOwner {
        msg.sender.transfer(ownerBalance);
    }
}