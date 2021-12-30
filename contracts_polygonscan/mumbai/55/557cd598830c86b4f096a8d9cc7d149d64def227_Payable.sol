/**
 *Submitted for verification at polygonscan.com on 2021-12-29
*/

pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

contract Payable
{
    struct VerificationData
    {
        address UserAddress;

        string UserID;

    }

    struct Goal
    {

        uint Id;

        string Titles;
        string Body;
        bool Important;


        uint StageImplementation;

        address User;

    }
    struct GoalDonate
    {

        uint Id;

        string Titles;
        string Body;
        bool Important;



        bool IsDonate;
        string DonateValue;
        string PublicAddress;

        uint StageImplementation;

        address User;

    }

    function toString(address x) internal pure returns (string memory) 
    {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) 
        {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) 
    {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    address payable owner;
    uint public price;
    VerificationData[] VerificationUserId;
    Goal[] Goals;
    GoalDonate[] DonateGoals;


    constructor(uint verificationCost) payable
    {
        owner = payable(msg.sender);

        price = verificationCost;
    }



    function allUserID() external view returns(string memory)
    {
        string memory allJsonIDstring;
        for (uint i = 0; i < VerificationUserId.length; i++)
        {
            string memory Addressw=toString(VerificationUserId[i].UserAddress);
            

            string memory userAddressJson=string(abi.encodePacked("{\"userAddress\":\"",Addressw,"\","));

            string memory userIDJson=string(abi.encodePacked("\"UserID\":\"",VerificationUserId[i].UserID,"\"}\n\r")); 
        
        
            string memory json=string(abi.encodePacked(userAddressJson,userIDJson));
           
                                
            allJsonIDstring=string(abi.encodePacked(allJsonIDstring,json));
        }
        
        


        return allJsonIDstring;
    }
    
 



    function AddVerifyProfile(string memory UserID) public payable
    {

        require (msg.value >= price,"insufficient funds");
        require (bytes(UserID).length == 36,"invalid id");


        VerificationData memory newVerificationData = VerificationData(payable(msg.sender),UserID);
        VerificationUserId.push(newVerificationData);

    }

    function AddDonateGoal
    (
        uint Id,
        string memory Titles,
        string memory Body,
        bool Important,
        bool IsDonate,
        string memory DonateValue,
        string memory PublicAddress,
        uint StageImplementation,
        address User
    ) public payable
    {

        GoalDonate memory NewGoal = GoalDonate(Id,Titles,Body,Important,IsDonate,DonateValue,PublicAddress,StageImplementation,User);
        DonateGoals.push(NewGoal);
    }


    function withdraw() public
    {

        if(msg.sender == owner)
        {
            uint amount = address(this).balance;

            (bool success,) = owner.call{value: amount}("");
            require(success, "Failed to send Ether");

        }
        else
        {
            require(false, "Not owner");
        }
    }



}