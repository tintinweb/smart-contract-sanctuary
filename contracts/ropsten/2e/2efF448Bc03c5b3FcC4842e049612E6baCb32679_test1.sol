pragma solidity >= 0.5.0;

contract test1
{
    uint test1 = 3;
    uint[] test2;
    
    constructor() public
    {
        //"H̡̫̤̤̣͉̤ͭ̓̓̇͗̎̀ơ̯̗̱̘̮͒̄̀̈ͤ̀͡w͓̲͙͖̥͉̹͋ͬ̊ͦ̂̀̚ ͎͉͖̌ͯͅͅd̳̘̿̃̔̏ͣ͂̉̕ŏ̖̙͋ͤ̊͗̓͟͜e͈͕̯̮̙̣͓͌ͭ̍̐̃͒s͙͔̺͇̗̱̿̊̇͞ ̸̤͓̞̱̫ͩͩ͑̋̀ͮͥͦ̊Z̆̊͊҉҉̠̱̦̩͕ą̟̹͈̺̹̋̅ͯĺ̡̘̹̻̩̩͋͘g̪͚͗ͬ͒o̢̖͇̬͍͇͓̔͋͊̓ ̢͈͙͂ͣ̏̿͐͂ͯ͠t̛͓̖̻̲ͤ̈ͣ͝e͋̄ͬ̽͜҉͚̭͇ͅx͎̬̠͇̌ͤ̓̂̓͐͐́͋͡ț̗̹̝̄̌̀ͧͩ̕͢ ̮̗̩̳̱̾w͎̭̤͍͇̰̄͗ͭ̃͗ͮ̐o̢̯̻̰̼͕̾ͣͬ̽̔̍͟ͅr̢̪͙͍̠̀ͅǩ̵̶̗̮̮ͪ́?̙͉̥̬͙̟̮͕ͤ̌͗ͩ̕͡ ";
        
    }
    
    function offset() public pure returns (uint)
    {
        uint a = 0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6;
        return uint(0-a);
    }
    
    function doTest() public returns (uint) {
        
        test2.length--;
        test2[offset()] = 33;
        return test1;
    }
    
    function testAboveLength() public returns (uint)
    {
        test2.push(1);
        return test2[3];
    }
    
    function getLength() public returns (uint) {
        
        return test2.length;
    }
}