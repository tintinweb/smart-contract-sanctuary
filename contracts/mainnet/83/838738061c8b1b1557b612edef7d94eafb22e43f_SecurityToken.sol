/**
 *Submitted for verification at Etherscan.io on 2020-05-15
*/

pragma solidity ^0.6.6;


/*
OWNER OF TOKEN: SAMUEL RICHARD PENN© TRUST

             
                                 NOTE
             
             

The original contract is signed, witnessed, sealed, stamped and held by the trustee of the SAMUEL RICHARD PENN© TRUST.
The token 08081986-SRP-CLC shall represent the certificate of title to the original bond. The holder in due course MUST possess the 08081986-SRP-CLC token to validate proof of claim.
Original documents can be seen and copies requested on www.samuelrichardpenn.com,
or on https://www.instagram.com/samuelrichardpenn/. Trustee can be reached at [email protected]
This token may never be sold. It can only be passed from a trust to a beneficiary.

Let the public be noticed of the following copyright.

Copyright Notice: All rights reserved.
Copyright  of  trade-name/trademark  SAMUEL  RICHARD  PENN©  TRUST  including  any  and  all  derivatives and variations in the spelling,
i.e. NOT limited to all capitalized names: SAMUEL RICHARD PENN TRUST ©. PENN©, SRP©, SAMUEL PENN©, PENN SAMUEL SR©, SR PENN© 
or any derivatives thereof are under Copyright 2004. Said common-law trade-name/trademark, SAMUEL RICHARD PENN© 
TRUST may neither be used nor reproduced, neither  in  whole  nor  in  part,  in  any  manner  whatsoever, 
without  the  prior,  express,  written  consent  and acknowledgment of Trustee/Trust in writing. 
With the Intent of being Contractually Bound, any Juristic Person, as well as the agent thereof, by notice of this copyright
is noticed that neither said Juristic Person nor agent thereof is authorized to display, 
nor otherwise use in any manner, the common-law trade-name/trademark nor the copyright described herein,
nor any derivative of, nor any variation  in  the  spelling  thereof, without  the  prior,  written  consent 
and  acknowledgment  of  Trustee/TRUST,  as signified in writing with signed consent. Trustee/Trust 
neither grants, nor implies, nor otherwise gives consent for any unauthorized use of SAMUEL RICHARD PENN©, 
and all such unauthorized use is strictly prohibited.
By receipt of this notice you are hereby made aware of this copyright if otherwise ignorant of the 
fact that said copyright is a matter of public record. This is notification that you are in BREACH. 
You herein have two options for remedy of this breach of copyright:
1)  You consent to the removal of information and discontinuation of use of all information held in copyright 
that contains copyrighted materials from all databases publications, chronicles, 
manifestos, newspapers, and/or records of any type and issue a written apology.; or
2)  If the first option of this section is neither effected or arrangements to affect cure of 
breach as described is not engaged within 10 days of return receipt of this Notice then the clause 
by default will be enacted and you consent to the following Self-executing Contract/Security 
Agreement in Event of Unauthorized Use as well as Payment Terms as described:

a)    Self-executing Contract/Security  Agreement in Event of Unauthorized Use: By this Notice, 
both the Juristic Person and the agent thereof, hereinafter .jointly and severally "User", consent 
and agree that any use of trade-name/trademark copyright other than authorized use as set forth herein, constitutes unauthorized use and  counterfeiting  of  property,  contractually  binds  User 
 and  renders  this  Notice  a  Security  Agreement wherein User is TRUST and SAMUEL RICHARD PENN TRUST© is Secured Party, and signifies that User:
b)    In accordance with the fees for unauthorized use of Trade-Name/Trademark/Copyright, as set forth herein, consents to be invoiced for outstanding balance and agrees that User shall pay TRUST all unauthorized use fees in full within thirty (30) days of the date User is sent "Invoice", 
itemizing said fees.
c)    Grants Trustee/TRUST the right to invoice three times at thirty day intervals at which time 
User consents to the outstanding balance that will be filed as a lien/levy via a UCC Financing 
Statement in the UCC filing office and/or in any county recorder's office, wherein User is TRUST 
and Trustee is Secured Party and that Secured Party may file such lien/levy against property


as a security interest in all of User's assets, land and personal property, and all of User's interest 
in assets, land and personal property, in the sum certain amount of $500,000.00 per each occurrence of use of the common-law copyrighted trade-name/trademark, plus costs, plus triple damages;
d)    Consent and agrees that said UCC Financing Statement described in "c" is a continuing 
financing statement, and further consents and agrees with TRUSTS filing of any continuation 
statement necessary for maintaining Secured  Party's  perfected  security  interest  in  all  of  
User's  property  and  interest  in  property  pledged  as collateral in this Security Agreement  
and  described herein until  User's contractual  obligation theretofore incurred has been fully 
satisfied;
e)    Waives all defenses; Consents and agrees that any and all such filings described herein going without remedy are not, and may not be considered, bogus/frivolous and that User will not claim such a defense in regard.
f)     Appoints  Secured  Party  as  Authorized  Representative  for  User,  effective  upon  
User's  default  re  User's contractual  obligations  in  favor  of  Secured  Obligation  as  set  
forth  herein  granting  TRUST/Trustee  full authorization and power for engaging in any and all 
actions on behalf of User including, but not limited to, authentication of a  record  on behalf  of 
 User as Secured  Party, at  Secured  Party's sole  discretion,  and as Secured Party deems 
appropriate, and User further consents and agrees that this appointment of Secured Party as 
Authorized Representative for User, effective upon User's default, is irrevocable and coupled with a security interest.
Terms of Strict Foreclosure: User's non-payment in full of all unauthorized use fees itemized in 
Invoice within said ninety  (90)  day  period  for  curing  default as  set  forth  within  
authorizes without  recourse Trustee/Secured  Party’s immediate non-judicial strict foreclosure on any and all remaining former property and interest in property,
formerly pledged as collateral by User, now property of Secured Party, which is not in the possession of,
nor otherwise disposed of by Secured Party upon expiration of said period. Samuel-Richard:  Penn,  Autograph 
Common  Law  Copyright  2004.  Unauthorized  use  of  "Samuel-Richard:  Penn" incurs same unauthorized-use fees as
those associated with SAMUEL RICHARD PENN© TRUST, as set forth in the first paragraph of the first page.







*/




contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
}

abstract contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public virtual returns (uint256 balance);
    function transfer(address _to, uint256 _value) public virtual returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);
    function approve(address _spender, uint256 _value) public virtual returns (bool success);
    function allowance(address _owner, address _spender) view public virtual returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is Owned,  ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
    function balanceOf(address _owner) view public virtual override returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public virtual override returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public virtual override returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public virtual override returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public virtual override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract SecurityToken is Token{
    
    constructor() public{
        symbol = "SRP";
        name = "08081986-SRP-CLC";
        decimals = 0;
        totalSupply = 1;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    receive () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }
}