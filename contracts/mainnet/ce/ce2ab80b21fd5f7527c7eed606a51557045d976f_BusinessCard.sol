pragma solidity ^0.4.24;

contract BusinessCard {
    
    address public jeremySchroeder;
    
    string public email;
    string public website;
    string public github;
    string public twitter;
    
    constructor () public {
        jeremySchroeder = msg.sender;
        email = &#39;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="7a101f081f17035409191208151f1e1f083a0a08150e1514171b1316541912">[email&#160;protected]</a>&#39;;
        website = &#39;https://spudz.org&#39;;
        github = &#39;https://github.com/spdz&#39;;
        twitter = &#39;https://twitter.com/_spdz&#39;;
    }
}