pragma solidity ^0.4.0;

contract splitwise {

struct Participant {
        uint amount;
        address partaddr;
    }
address private _owner;
uint numberofparti = 0;
uint totalamountcol = 0;
mapping (address => bool)  partifunded;
mapping (address => bool)  withdrawed;

Participant[] participants;
uint billamount;

modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

 constructor()
        public {
        _owner = msg.sender;
    }


function checkcontractbalance() public view returns (uint) {

        return address(this).balance;
    }

function () public payable {

    addfund();
}

function amIfunded() public view returns (bool)
{
    return partifunded[msg.sender];

}

function didIwithdraw() public view returns (bool)
{
    return withdrawed[msg.sender];

}
function get_totalamountcol() public view returns (uint)
{
    return totalamountcol;

}

function get_numberofparti() public view returns (uint)
{
    return numberofparti;

}

function setbillamount(uint _billamount) public isOwner {

    billamount = _billamount;
}

function addfund() payable public {

    if (partifunded[msg.sender] == true) {
        for ( uint i = 0; i < participants.length; i++) {
            if (participants[i].partaddr == msg.sender)
             {
                participants[i].amount += msg.value;
                totalamountcol = address(this).balance;
             }
        }
    }
    else
    {
        partifunded[msg.sender] = true;
        participants.push(Participant(msg.value,msg.sender));
        numberofparti = numberofparti+1;
        totalamountcol = address(this).balance;
    }

}

function paybill  ( address _biller) public {

    if (address(this).balance > billamount ) {
        _biller.transfer(billamount);
    }
}

function findremainingamount() public view returns ( uint ) {

uint localtotalamount ;
uint remainingamount ;
for (uint j = 0; j < participants.length; j++) {
            localtotalamount = participants[j].amount + localtotalamount;
        }
remainingamount = localtotalamount - billamount ;
return remainingamount;

}

function simpleratio() public view returns (int){
    int a = 10000000000000000000/1000000000;
    int b = 20000000000000000000/1000000000;
    int c = 40000000000000000000/1000000000;
    int d = a * (b/c);
    return d;

}

function withdraw() public {

uint partshare;
uint balanceamount ;
uint remainingamount = findremainingamount();
if (withdrawed[msg.sender] != true) {

    withdrawed[msg.sender] = true;
    for (uint k = 0; k < participants.length; k++) {
            if (participants[k].partaddr == msg.sender) {
                    partshare = participants[k].amount;
                }
        }

    balanceamount = uint(partshare)*(uint(remainingamount) /  uint(totalamountcol))  ;
    msg.sender.transfer(partshare*(remainingamount/totalamountcol) );
    }

}

function retunmoneytoowner() isOwner public {
    msg.sender.transfer(address(this).balance);
}

}