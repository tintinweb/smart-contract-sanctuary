// Write your own contracts here.
pragma solidity ^0.8.9;
contract UniTwi {
  uint constant MAX_LESSON_LENGTH = 512;
  uint constant PAGE_SIZE = 20;

  struct FriendshipReport {
    address author;
    string lesson;
  }

  // Contains all reports.
  FriendshipReport[] private _book;

  // Contains all authors that have reports in the _book.
  address[] private _authors;

  // Contains the indices of the reports in the _book by this author incremented by one.
  mapping(address => mapping(uint => uint)) private _bookmarks;

  // Contains the number of the reports by this author.
  mapping(address => uint) private _reports;

  function todayILearned(string calldata lesson) public {
    require(bytes(lesson).length <= MAX_LESSON_LENGTH, "The lesson must be short!");
    FriendshipReport memory report = FriendshipReport(msg.sender, lesson);
    _book.push(report);
    uint reportIndex = _reports[msg.sender];
    if (reportIndex == 0) {
        _authors.push(msg.sender);
    }
    _bookmarks[msg.sender][reportIndex] = _book.length;
    _reports[msg.sender] = reportIndex + 1;
  }

  function whatWeHaveLearnedSoFar(uint page) public view returns (FriendshipReport[PAGE_SIZE] memory) {
    FriendshipReport[PAGE_SIZE] memory reports;
    uint firstReportIndex = page * PAGE_SIZE;
    uint lastReportIndex = firstReportIndex + PAGE_SIZE;
    if (_book.length < lastReportIndex) {
        lastReportIndex = _book.length;
    }
    for (uint reportIndex = firstReportIndex; reportIndex < lastReportIndex; reportIndex++) {
        reports[reportIndex - firstReportIndex] = _book[reportIndex];
    }

    return reports;
  }

  function whatXHaveLearnedSoFar(address author, uint page) public view returns (FriendshipReport[PAGE_SIZE] memory) {
    FriendshipReport[PAGE_SIZE] memory reports;
    uint firstReportIndex = page * PAGE_SIZE;
    uint lastReportIndex = firstReportIndex + PAGE_SIZE;
    for (uint reportIndex = firstReportIndex; reportIndex < lastReportIndex; reportIndex++) {
        uint bookIndex = _bookmarks[author][reportIndex];
        if (bookIndex == 0) break;
        reports[reportIndex - firstReportIndex] = _book[bookIndex - 1];
    }

    return reports;
  }

  function faithfulStudents(uint page) public view returns (address[PAGE_SIZE] memory) {
    address[PAGE_SIZE] memory authors;
    uint firstAuthorIndex = page * PAGE_SIZE;
    uint lastAuthorIndex = firstAuthorIndex + PAGE_SIZE;
    if (_authors.length < lastAuthorIndex) {
        lastAuthorIndex = _authors.length;
    }
    for (uint authorIndex = firstAuthorIndex; authorIndex < lastAuthorIndex; authorIndex++) {
        authors[authorIndex - firstAuthorIndex] = _authors[authorIndex];
    }

    return authors;
  }
}