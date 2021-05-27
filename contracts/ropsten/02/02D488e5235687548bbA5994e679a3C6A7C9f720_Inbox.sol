/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Inbox {
    struct Mail {
        uint256 to;
        uint256 time;
        bool isSent;
        string subject;
        string message;
        string[] names;
        string[] paths;
        uint256[] sizes;
    }

    mapping(uint256 => Mail[]) public mails;

    function send(
        uint256 _from,
        uint256 _to,
        uint256 _time,
        string memory _subject,
        string memory _message,
        string[] memory _names,
        string[] memory _paths,
        uint256[] memory _sizes
    ) public {
        Mail memory _mail;

        //Common data for sent mail and received mail
        _mail.time = _time;
        _mail.subject = _subject;
        _mail.message = _message;
        _mail.names = _names;
        _mail.paths = _paths;
        _mail.sizes = _sizes;

        //Set data for sent mail
        _mail.to = _to;
        _mail.isSent = true;
        mails[_from].push(_mail);

        //Set data for received mail
        _mail.to = _from;
        _mail.isSent = false;
        mails[_to].push(_mail);

        emit Send(
            _from,
            _to,
            _time,
            _subject,
            _message,
            _names,
            _paths,
            _sizes
        );
    }

    function getMails(uint256 _from) public view returns (Mail[] memory) {
        return mails[_from];
    }

    event Send(
        uint256 indexed _from,
        uint256 indexed _to,
        uint256 indexed _time,
        string _subject,
        string _message,
        string[] _names,
        string[] _paths,
        uint256[] _sizes
    );
}