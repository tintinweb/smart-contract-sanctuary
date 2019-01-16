pragma solidity 0.4.25;

contract TestOpenSourceB {
using SafeMath for *;

string constant public name   = "Test Open Souce Cook";
string constant public symbol = "TOC";

constructor() public {
    // does no thing
}

event onTest (
    uint256 ttt
);

uint256[] array = [1,2,3,4,5];

function addZeroTest() public {
    uint256 _share = 200000000000000000;
    emit onTest(_share);
}

function() public payable {
    uint256 k_ = 3;
    emit onTest(k_);
}

function generateRandom()
    public
    view
    returns(uint256)
{
    uint256 seed = uint256(keccak256(abi.encodePacked(
        (block.timestamp).add
        (block.difficulty).add
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
        (block.gaslimit).add
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
        (block.number)
    )));
    seed = (seed % 100000000) + 1;
    //seed = (seed - ((seed / 100000000) * 100000000) + 1;
    return seed;
}
}

library SafeMath {

/**
* @dev Multiplies two numbers, throws on overflow.
*/
function mul(uint256 a, uint256 b) 
    internal 
    pure 
    returns (uint256 c) 
{
    if (a == 0) {
        return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
}

/**
* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256) 
{
    require(b <= a, "SafeMath sub failed");
    return a - b;
}

/**
* @dev Adds two numbers, throws on overflow.
*/
function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256 c) 
{
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
}

/**
 * @dev gives square root of given x.
 */
function sqrt(uint256 x)
    internal
    pure
    returns (uint256 y) 
{
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y) 
    {
        y = z;
        z = ((add((x / z),z)) / 2);
    }
}

/**
 * @dev gives square. multiplies x by x
 */
function sq(uint256 x)
    internal
    pure
    returns (uint256)
{
    return (mul(x,x));
}

/**
 * @dev x to the power of y 
 */
function pwr(uint256 x, uint256 y)
    internal 
    pure 
    returns (uint256)
{
    if (x==0)
        return (0);
    else if (y==0)
        return (1);
    else 
    {
        uint256 z = x;
        for (uint256 i=1; i < y; i++)
            z = mul(z,x);
        return (z);
    }
}
}