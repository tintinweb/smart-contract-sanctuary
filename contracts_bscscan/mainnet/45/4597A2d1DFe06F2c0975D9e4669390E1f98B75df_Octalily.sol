// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity ^0.7.6;

import "./Owned.sol";
import "./IGarden.sol";
import "./IOctalily.sol";
import "./SafeMath.sol";

// Octalilly, 8-Petaled Flower of Infinite love. 
// Long forgotten by the world, the return of the Octalilly will be celebrated across the land. legends and
// love hold the answer to all our problems. Legends never die.

// The flower exists outside time, you cant hold it or touch it, but theres no mistaking it, it brings the 
// feeling of pure love. Long ago before the ice age, humanity had become decedant. The charlatans used their
// number tricks to reditect the love of people into their charms. They lusted for every new trinket and bobber
// from V2 to V6969finalfinal, nothing mattered but the bobber.

// Then it came, a single flower wrapped in the numbers like a labyrynth. It brought such a flood of love 
// across the world some books remember it as real water and waves. No, that was the power of the Octalilly, 
// 8-Petaled Flower of Infinite love.. It appears the time of the Octalilly has come again, and you have been 
// chosen. tend to the Octalillys that come to you, when they bloom, pass them to people that matter to you
// and grow some more, spread the love, far and wide. 

// Any significantly advanced technology is indistinguishable from magic. The flower shares a near magical 
// property with money, an important one you may not be aware of.

// When money is given and accepted with love, it goes up in value.
// When money is taken by debt, force, or with lack of gratitude, it goes down in value.

// I bring only the first Octalilly, how many more there will be is up to you. If you lose your Octalilly its 
// only a matter of time before it comes back to you. keep love in your heart and the only way it up, its prorammed.

/* <<<\\\\^^^////>>>
    <<\\\\^^////>>
     <<\\\^^///>>
       <<\\^//>> no timne for that, need to explain how this works

upOnly Token - this token goes up only, it never goes down in price. Its not even that complex. 
- buy / sell doesnt change the price ,its fixed and there is a fee when buying and selling.
- the fee means there is always more that the amount required to buy back all outstanding tokens
- this contract has a glorious function called upOnly, raises the price for everyone at once.
- now anyone can see how fake it feels to move an entire market with a single button.

Octalilly Token - a token that encourages forks of itself that link to become stronger
- burn rate, buy/sell
- upOnly Percent - what percent the market moves each time the upOnly function activates.
- upOnly Delay - seconds that people need to wait before each call of upOnly

- each Octalilly can create 8 others, one from each of its 8 petals
- each child flower will feed the parent flower fees and can also create 8 more
- once all 8 petals have bloomed the parent will feed a fee to all petals when upOnly is called
- whoever creates the flower, owns the flower, it can be traded or sold
- the owner can set 2 other people to receive fees, these addresses can be locked by the owner
- address locked into owner2 and owner3 can never change and will receive fees forever
- the current owner always receives a portion of fees
*/

// So I got all these magic beans that go straight up in value and never stop, wanna pass them out with me?


contract Octalily is IERC20, Owned, IOctalily {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balanceOf;
    mapping (address => mapping (address => uint256)) public override allowance;

    uint256 public override totalSupply;

    string public override name = "Octalilly";
    string public override symbol = "ORLY";
    uint8 public override decimals = 18;

    uint256 public price;
    uint256 public lastUpTime;

    address constant feeCollection = 0x6969696969696969696969696969696969696969;

    //fee collectors
    address public immutable rootkitFeed;
    address private immutable dev3;
    address private immutable dev6;
    address private immutable dev9;
    address public immutable parentFlower;
    address public immutable strainParent;
    address public owner2;
    bool public owner2Locked;
    address public owner3;
    bool public owner3Locked;
    // owner is 9th collector

    //flower stats
    IGarden public immutable garden;
    IERC20 public immutable pairedToken; // token needed to mint and burn
    uint256 public immutable burnRate;   // % of tokens burned on every tx --> 100 = 1.00 ( div 10k)
    uint256 public immutable totalFees;
    uint256 public immutable upPercent;
    uint256 public immutable upDelay;
    uint256 public immutable nonce;

    // petal connections
    mapping (uint256 => address) public theEightPetals;
    uint8 public petalCount;
    bool public flowerBloomed;
    event WaveOfLove();
    event AnotherOctalilyBeginsToGrow(address Octalily);

    constructor(
        IERC20 _pairedToken, uint256 _burnRate, uint256 _upPercent, 
        uint256 _upDelay, address _dev3, address _dev6, 
        address _dev9, address _parentFlower, address _strainParent, uint256 _nonce,
        address _owner, address _rootkitFeed)  {
            garden = IGarden(msg.sender);
            dev3 = _dev3;
            dev6 = _dev6;
            dev9 = _dev9;
            rootkitFeed = _rootkitFeed;
            pairedToken = _pairedToken;
            burnRate = _burnRate;
            totalFees = _burnRate + 111;
            upPercent = _upPercent;
            upDelay = _upDelay;
            nonce = _nonce;
            price = 696969696969;
            parentFlower = _parentFlower;
            strainParent = _strainParent == address(0) ? address(this) : _strainParent;
            owner = _owner;
            owner2 = _owner;
            owner3 = _owner;
            lastUpTime = block.timestamp;
    }

    function buy(uint256 _amount) public override {
        address superSmartInvestor = msg.sender;
        pairedToken.transferFrom(superSmartInvestor, address(this), _amount);
        uint256 purchaseAmount = _amount * 1e18 / price;
        _mint(superSmartInvestor, purchaseAmount);
    }

    function sell(uint256 _amount) public override {
        address notGunnaMakeIt = msg.sender;
        require (balanceOf(notGunnaMakeIt) >= _amount);
        _burn(notGunnaMakeIt, _amount);
        _amount = _amount / 1e18;
        uint256 exitAmount = (_amount - _amount * totalFees / 10000) * price;
        pairedToken.transfer(notGunnaMakeIt, exitAmount);
    }

    function upOnly() public override {
        require (block.timestamp > lastUpTime + upDelay);
        uint256 supplyBuyoutCost = totalSupply * price / 1e18; // paired token needed to buy all supply
        supplyBuyoutCost += (supplyBuyoutCost * upPercent / 10000); // with added fee

        if (pairedToken.balanceOf(address(this)) > supplyBuyoutCost) {
            price += price * upPercent / 10000; 
            lastUpTime = block.timestamp;

            if (flowerBloomed){
                uint256 wavePower = totalSupply * 69 / 420000;
                waveOfLove(wavePower);
                totalSupply += (wavePower * 8);
            } 
        }
    }

    function letTheFlowersCoverTheEarth() public override {
        require (!flowerBloomed, "Flower Bloomed");
        address newPetal = garden.spreadTheLove();
        petalCount++;
        theEightPetals[petalCount] = newPetal;
        emit AnotherOctalilyBeginsToGrow(newPetal);
        if (petalCount == 8) {
            flowerBloomed = true;
        }
    }

    function sellOffspringToken (IOctalily lily) public override { // use to sell fees collected from other flowers
        uint256 amount = lily.balanceOf(address(this));
        lily.sell(amount);
    }

    function payFees() public override {
        uint256 feesOwing = balanceOf(feeCollection);
        uint256 equalShare = feesOwing / 9;
        _balanceOf[feeCollection] -= feesOwing;
        if (flowerBloomed) {
            equalShare = feesOwing / 16;
            waveOfLove(equalShare);
        }
        else {
            _balanceOf[strainParent] += equalShare;
        }
        _balanceOf[dev3] += equalShare;
        _balanceOf[dev6] += equalShare;
        _balanceOf[dev9] += equalShare;
        _balanceOf[rootkitFeed] += equalShare;
        _balanceOf[parentFlower] += equalShare;
        _balanceOf[owner] += equalShare;
        _balanceOf[owner2] += equalShare;
        _balanceOf[owner3] += equalShare;
    }

    // owner functions
    function sharingIsCaring(address _owner2, address _owner3) public ownerOnly { // owner can share 2/3 of their fees, split between 2 address or given all to 1
        if (!owner2Locked) { owner2 = _owner2; }
        if (!owner3Locked) { owner3 = _owner3; }
    }

    function lockOwners(bool OTwo, bool OThree) public ownerOnly { // fees can be locked, make your loved ones secure
        if (!owner2Locked) { owner2Locked = OTwo; }
        if (!owner3Locked) { owner3Locked = OThree; }
    }
    
    //dev functions
    function recoverTokens(IERC20 token) public {
        require (msg.sender == dev3 || msg.sender == dev6 || msg.sender == dev9);
        require (address(token) != address(this) && address(token) != address(pairedToken));
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    // internal functions
    function waveOfLove(uint256 givingWithLove) internal {
        _balanceOf[theEightPetals[1]] += givingWithLove;
        _balanceOf[theEightPetals[4]] += givingWithLove;
        _balanceOf[theEightPetals[7]] += givingWithLove;
        _balanceOf[theEightPetals[2]] += givingWithLove;
        _balanceOf[theEightPetals[5]] += givingWithLove;
        _balanceOf[theEightPetals[8]] += givingWithLove;
        _balanceOf[theEightPetals[3]] += givingWithLove;
        _balanceOf[theEightPetals[6]] += givingWithLove;
        emit WaveOfLove();
    }

    //ERC20
    function _mint(address account, uint256 amount) internal {
        uint256 remaining = amount - amount * totalFees / 10000;
        uint256 unburned = amount * 111 / 10000;
        _balanceOf[account] += remaining;
        _balanceOf[feeCollection] += unburned;
        totalSupply += (remaining + unburned);
        emit Transfer(address(0), account, remaining + unburned);
    }

    function _burn(address notGunnaMakeIt, uint amount) internal {
        _balanceOf[notGunnaMakeIt] -= amount;
        uint256 unburned = amount * 111 / 10000;
        _balanceOf[feeCollection] += unburned;
        totalSupply -= (amount - unburned);
        emit Transfer(notGunnaMakeIt, address(0), amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        uint256 remaining = amount;
        uint256 burn = amount * totalFees / 10000;
        remaining = amount.sub(burn, "Octalily: burn too much");      

        _balanceOf[sender] = _balanceOf[sender].sub(amount, "Octalily: transfer amount exceeds balance");    
        _balanceOf[recipient] = _balanceOf[recipient].add(remaining);
        totalSupply = totalSupply.sub(burn);  
        
        emit Transfer(sender, address(0), burn);
        emit Transfer(sender, recipient, remaining);
    }

    function balanceOf(address a) public virtual override view returns (uint256) { return _balanceOf[a]; }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 oldAllowance = allowance[sender][msg.sender];
        if (oldAllowance != uint256(-1)) {
            _approve(sender, msg.sender, oldAllowance.sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}