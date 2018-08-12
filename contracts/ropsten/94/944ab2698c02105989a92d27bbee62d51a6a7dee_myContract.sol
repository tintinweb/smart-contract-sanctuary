pragma solidity ^0.4.0;

contract myContract
{

// a structure that stores bets

struct Bets{
    uint betNum; // some int number
}

mapping(address => Bets[]) myBetMapping;

function addBet(uint n) returns(uint)
{
    Bets memory l;
    l.betNum = n;
    myBetMapping[msg.sender].push(l);

   //check the last bet is added or not

   return myBetMapping[msg.sender][myBetMapping[msg.sender].length -1].betNum;

}

// lets modify the mapping and the array

function modifyBet(uint n, uint index) returns(uint,uint,uint)
{
    /*
    Bets memory l;
    l.betNum = n;

    add new bet

    myBetMapping[msg.sender].push(l);
    return myBetMapping[msg.sender][myBetMapping[msg.sender].length -1].betNum;
    */
    /*
    add new bet at index

     delete myBetMapping[msg.sender][index];
     myBetMapping[msg.sender][index] = l;

     // return the added value

     return myBetMapping[msg.sender][index].betNum;
    */
    /*
    deleting a bet and reducing the length , (index starts from 0)

    //delete the struct 

    delete myBetMapping[msg.sender][index];

    for(uint i = index ;i<myBetMapping[msg.sender].length-1; i++)
    {
        // shifts value to left
        myBetMapping[msg.sender][i] =  myBetMapping[msg.sender][i+1];

    }

     //deleting the last value
     delete myBetMapping[msg.sender][myBetMapping[msg.sender].length-1];

     //reducing the length
     myBetMapping[msg.sender].length--;

     //checking evrything works fine or not by returning the last value, the second last and the length
     return (myBetMapping[msg.sender][index].betNum,myBetMapping[msg.sender][myBetMapping[msg.sender].length-1].betNum,myBetMapping[msg.sender].length);
    */
}
}

//This should solve your problem :) enjoy!