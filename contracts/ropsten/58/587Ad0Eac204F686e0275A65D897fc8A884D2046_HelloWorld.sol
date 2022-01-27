pragma solidity 0.8.0;
contract HelloWorld
{

string private greeting;
constructor() public {

greeting="Hello World from Blockchain";

}
function displayGreeting() public view returns(string memory)
{
return greeting;

}



}