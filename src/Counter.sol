// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EduChain is ERC721, Ownable {
    uint public nextClassId;
    uint public nextStudentId;
    uint public nextAssignmentId;
    uint public nextNFTId;

    struct Class {
        uint classId;
        address instructor;
        string title;
        uint createdAt;
    }

    struct Assignment {
        uint assignmentId;
        string description;
        uint submissionCount;
        uint createdAt;
    }

    struct Student {
        uint studentId;
        string name;
        mapping(uint => bool) assignmentsSubmitted; // Track assignment submissions by assignmentId
        mapping(uint => uint) assignmentScores; // Track assignment scores
        uint totalScore;
    }

    struct ClassroomInstance {
        uint classId;
        mapping(address => bool) enrolledStudents; // Track which students are enrolled
        Assignment[] assignments; // Track assignments for the class
        mapping(address => Student) students; // Track student performance in the class
        uint passMark;
    }

    mapping(uint => ClassroomInstance) public classrooms;
    mapping(address => uint) public participationNFTs; // NFT tracking for participation
    mapping(address => bool) public teachers;

    event ClassCreated(uint classId, address instructor, string title, uint createdAt);
    event StudentEnrolled(uint classId, address student);
    event AssignmentSubmitted(uint classId, address student, uint assignmentId);
    event AssignmentMarked(uint classId, address student, uint assignmentId, uint score);
    event NFTAwarded(address student, uint tokenId);

    modifier onlyInstructor(uint classId) {
        require(teachers[msg.sender] == true, "Only instructors can perform this action");
        require(classrooms[classId].classId != 0, "Class does not exist");
        _;
    }

    constructor() ERC721("EduChain Participation", "EDU") {}

    function createClass(string memory _title, uint _passMark) external onlyOwner {
        require(teachers[msg.sender], "Only instructors can create classes");

        nextClassId++;
        ClassroomInstance storage newClass = classrooms[nextClassId];
        newClass.classId = nextClassId;
        newClass.passMark = _passMark;
        newClass.students[msg.sender].name = "Instructor";  // Admin starts as instructor

        emit ClassCreated(nextClassId, msg.sender, _title, block.timestamp);
    }

    function addAssignment(uint classId, string memory _description) external onlyInstructor(classId) {
        Assignment memory newAssignment = Assignment({
            assignmentId: nextAssignmentId,
            description: _description,
            submissionCount: 0,
            createdAt: block.timestamp
        });
        classrooms[classId].assignments.push(newAssignment);
        nextAssignmentId++;
    }

    function enrollStudent(uint classId, string memory studentName) external {
        ClassroomInstance storage classroom = classrooms[classId];
        require(classroom.classId != 0, "Class does not exist");
        require(!classroom.enrolledStudents[msg.sender], "Already enrolled");

        nextStudentId++;
        Student storage student = classroom.students[msg.sender];
        student.studentId = nextStudentId;
        student.name = studentName;
        classroom.enrolledStudents[msg.sender] = true;

        emit StudentEnrolled(classId, msg.sender);
    }

    function submitAssignment(uint classId, uint assignmentId) external {
        ClassroomInstance storage classroom = classrooms[classId];
        require(classroom.enrolledStudents[msg.sender], "You must be enrolled in the class");
        require(assignmentId < classroom.assignments.length, "Invalid assignment ID");

        Student storage student = classroom.students[msg.sender];
        require(!student.assignmentsSubmitted[assignmentId], "Assignment already submitted");

        student.assignmentsSubmitted[assignmentId] = true;
        classroom.assignments[assignmentId].submissionCount++;

        emit AssignmentSubmitted(classId, msg.sender, assignmentId);
    }

    function markAssignment(uint classId, address studentAddress, uint assignmentId, uint score) external onlyInstructor(classId) {
        ClassroomInstance storage classroom = classrooms[classId];
        Student storage student = classroom.students[studentAddress];
        require(student.assignmentsSubmitted[assignmentId], "Assignment not submitted");

        student.assignmentScores[assignmentId] = score;
        student.totalScore += score;

        emit AssignmentMarked(classId, studentAddress, assignmentId, score);
    }

    function issueParticipationNFT(address studentAddress, uint classId) external onlyInstructor(classId) {
        Student storage student = classrooms[classId].students[studentAddress];
        require(student.totalScore >= classrooms[classId].passMark, "Student did not pass");

        nextNFTId++;
        _safeMint(studentAddress, nextNFTId);
        participationNFTs[studentAddress] = nextNFTId;

        emit NFTAwarded(studentAddress, nextNFTId);
    }

    function getStudentScore(uint classId, address studentAddress) external view returns (uint) {
        return classrooms[classId].students[studentAddress].totalScore;
    }

    function getAssignmentCount(uint classId) external view returns (uint) {
        return classrooms[classId].assignments.length;
    }

    function getStudentAssignmentStatus(uint classId, uint assignmentId, address studentAddress) external view returns (bool) {
        return classrooms[classId].students[studentAddress].assignmentsSubmitted[assignmentId];
    }
    
    // Additional functions for managing instructors
    function addInstructor(address instructor) external onlyOwner {
        teachers[instructor] = true;
    }

    function removeInstructor(address instructor) external onlyOwner {
        teachers[instructor] = false;
    }
}
