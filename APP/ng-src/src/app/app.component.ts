import { Component, OnInit } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { MainService } from './services/main.service';
import Swal from 'sweetalert2';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-root',
  imports: [
    RouterOutlet,
    CommonModule,
    FormsModule
  ],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent implements OnInit {

  constructor(
    private MainAPI: MainService
  ) {

  }
  
  menu: any = [
    {
      id: "config",
      icon: "fas fa-cog",
      name: "Configuración Inicial",
      description: "Inicialice las variables iniciales del aplicativo",
      selected: false
    },
    {
      id: "academic_period",
      icon: "fas fa-graduation-cap",
      name: "Periodos Academicos",
      description: "Inicialice las variables iniciales del aplicativo",
      selected: false
    },
    {
      id: "students",
      icon: "fas fa-users",
      name: "Registro de Estudiantes",
      description: "Administre la información de los estudiantes",
      selected: false
    },
    {
      id: "enrollment",
      icon: "fas fa-list-check",
      name: "Matricula",
      description: "Administre la Estudiantes por Periodo y Grado",
      selected: false
    },
    {
      id: "scores",
      icon: "fas fa-star",
      name: "Registro de Notas",
      description: "Seleccione una materia o período para gestionar las calificaciones",
      selected: false
    },
    {
      id: "descriptive_conclusions",
      icon: "fas fa-book",
      name: "Registro de Conclusiones Descriptivas",
      description: "Registre el logro, dificultad y recomendaciones de los estudiantes",
      selected: false
    },
    {
      id: "report_card",
      icon: "fas fa-list-check",
      name: "Boleta de Notas",
      description: "Visualice la boleta de notas de los estudiantes",
      selected: false
    },
  ];

  itemSelected: any = undefined;

  allStudents: any[] = [];
  genders: any[] = [];
  studentStatus: any[] = [];
  studentFounds: any[] = [];
  periods: any[] = [];
  grades: any[] = [];
  gradeInAcademicPeriods: any[] = [];
  courses: any[] = [];
  studentsInGrade: any[] = [];
  coursesInGrade: any[] = [];
  competences: any[] = [];
  academicPeriods: any[] = [];
  currentAcademicPeriod: any;
  studentToEnrollment: any;

  romanNumbers: any = {
    1: "I",
    2: "II",
    3: "III",
    4: "IV",
    5: "V",
    6: "VI",
    7: "VII",
    8: "VIII",
    9: "IX",
    10: "X",
    11: "XI",
    12: "XII"
  };

  filter: any = {
    students: {
      text: undefined
    },
    academic_periods: {
      text: undefined
    },
    enrollment: {
      textoToSearch: undefined
    }
  };

  showForm: boolean = false;
  newItem: any;

  ngOnInit(): void {
    console.log("Iniciando proyecto");
    this.getTypes();
    this.getStudents();
    this.getPeriods();
    this.getCourses();
    this.getStudentsInGrade();
  }

  async getTypes() {
    let resultGenders = await this.MainAPI.getEntitiesBy('types', {filter: {type: "GENERO"}});
    this.genders = resultGenders.data;
    
    let resultStudentStatus = await this.MainAPI.getEntitiesBy('types', {filter: {type: "ESTADO-DE-REGISTRO"}});
    this.studentStatus = resultStudentStatus.data;
  }

  async getPeriods() {
    let result: any = await this.MainAPI.getEntitiesBy('periods', {filter: [{}]});
    console.log(result);
    this.periods = result.data;
  }

  async getStudentsInGrade() {
    let result: any = await this.MainAPI.getEntitiesBy('students_in_grade', {filter: [{}]});
    this.studentsInGrade = result.data;

    let resultCourses: any = await this.MainAPI.getEntitiesBy('courses_in_grade', {filter: [{}]});
    this.coursesInGrade = resultCourses.data;

    let resultCompetences: any = await this.MainAPI.getEntitiesBy('competences', {filter: [{}]});
    this.competences = resultCompetences.data;

    this.getGrades();
  }

  
  async getGrades() {
    let result: any = await this.MainAPI.getEntitiesBy('grades', {filter: [{}]});
    this.grades = result.data;
    this.getGradesInAcademicPeriods();
  }
  
  async getCourses() {
    let result: any = await this.MainAPI.getEntitiesBy('courses', {filter: [{}]});
    this.courses = result.data;
  }
  
  async getGradesInAcademicPeriods() {
    let result: any = await this.MainAPI.getEntitiesBy('grade_in_academic_periods', {filter: [{}]});
    this.gradeInAcademicPeriods = result.data;
    this.getAcademicPeriods();
  }

  async getAcademicPeriods() {
    let result: any = await this.MainAPI.getEntitiesBy('academic_periods', {filter: [{}]});
    this.academicPeriods = result.data;
    this.academicPeriods.map((a) => {
      a.grades = JSON.parse(JSON.stringify(this.grades));
    });

    this.academicPeriods.map((a) => {
      a.grades.map((g: any) => {
        let gradeWithData = this.gradeInAcademicPeriods.find((x: any) => x.academic_period_id === a.id && x.grade_id === g.id);
        if (gradeWithData) {
          g.vacancies = gradeWithData.vacancies;
          g.selected = true;
          g.grade_in_academic_period_id = gradeWithData.id;
        }
      });
      a.withGrades = a.grades.filter((g: any) => g.grade_in_academic_period_id).length > 0;
      a.grades.map((g: any) => {
        g.students = this.studentsInGrade.filter((s: any) => s.grade_in_academic_period_id === g.grade_in_academic_period_id);
      });

      a.grades.map((g: any) => {
        g.courses = JSON.parse(JSON.stringify(this.courses));
        g.courses.map((c: any) => {
          let courseInGradeFound: any = this.coursesInGrade.find((x: any) => x.grade_in_academic_period_id === g.grade_in_academic_period_id && x.course_id === c.id);
          if (courseInGradeFound) {
            c.courses_in_grade_id = courseInGradeFound.id;
            c.selected = true;
          }
        });
        // g.courses = this.coursesInGrade.filter((s: any) => s.grade_in_academic_period_id === g.grade_in_academic_period_id);
        g.courses.filter((x: any) => x.courses_in_grade_id).map((c: any) => {
          c.competences = this.competences.filter((cm: any) => cm.courses_in_grade_id === c.courses_in_grade_id);
        });
      });
    });
    this.getInitialVarsToEnrollment();
  }

  async getInitialVarsToEnrollment() {
    let result: any = await this.MainAPI.getEntitiesBy('academic_periods', {filter: [{is_current: true}]})
    console.log(result);
    if (result.data.length) {
      this.currentAcademicPeriod = this.academicPeriods.find((a: any) => a.id === result.data[0].id) ;
      console.log(this.gradeInAcademicPeriods);
    }
  }

 

  selectItem(item: any) {
    this.itemSelected = item;
  }

  async getStudents() {
    try {
      let result = await this.MainAPI.getEntitiesBy('students',{filter: {}});
      console.log(result);
      if (!result.success) {
        Swal.fire({
          title: 'Error!',
          text: result.error,
          icon: 'error',
        });
        return;
      }
      this.allStudents = result.data;
    } catch (error) {
      console.log(error);
    }
  }

  toggleSidebar(type: string, item?: any) {
    this.showForm = !this.showForm;
    if (this.showForm) {
      this.newItem = {};
      if (item) {
        this.newItem = JSON.parse(JSON.stringify(item));
        this.newItem.editing = true;
      }
      this.newItem.typeSelected = type;
    } else {
      this.newItem = {};
    }
    
  }

  async saveItem(item?: any) {
    let result;
    let body: any = {
      news: [this.newItem]
    };
    switch (this.newItem.typeSelected) {
      case "student":
        let bodyPerson = {
          news: [
            {
              code: this.newItem.code,
              father_last_name: this.newItem.father_last_name,
              mother_last_name: this.newItem.mother_last_name,
              names: this.newItem.names,
              gender: this.newItem.gender,
              created_by: 1,
            }
          ]
        };
        
        let resultPerson = await this.MainAPI.saveEntities('persons', bodyPerson);
        console.log(resultPerson);

        let personFound = resultPerson.data.find((d: any) => d.code === this.newItem.code);

        this.newItem.person_id = personFound.id;
        body = {
          news: [
            {
              person_id: personFound.id,
              status: this.newItem.status,
              created_by: 1
            }
          ]
        };
        result = await this.MainAPI.saveEntities('students',body);
        console.log(result);
        if (!result.success) {
          Swal.fire({
            text: result.message,
            icon: 'error'
          });
          return;
        }
        Swal.fire({
          text: 'Se realizo correctamente la operación',
          icon: 'success'
        });
        break;
      case 'period':
        if (!this.newItem.editing) {
          body = {
            news: [this.newItem]
          };
          result = await this.MainAPI.saveEntities('periods', body);
        } else {
          body = {
            updateds: [this.newItem]
          };
          result = await this.MainAPI.updateEntities('periods', body);
        }
        if (!result.success) {
          Swal.fire({
            text: result.message,
            icon: 'error'
          });
          return;
        }
        Swal.fire({
          text: 'Se realizo correctamente la operación',
          icon: 'success'
        });
        break;
      case 'grade':
        if (!this.newItem.editing) {
          body = {
            news: [this.newItem]
          };
          result = await this.MainAPI.saveEntities('grades', body);
        } else {
          body = {
            updateds: [this.newItem]
          };
          result = await this.MainAPI.updateEntities('grades', body);
        }
        if (!result.success) {
          Swal.fire({
            text: result.message,
            icon: 'error'
          });
          return;
        }
        Swal.fire({
          text: 'Se realizo correctamente la operación',
          icon: 'success'
        });
        break;
      case 'course':
        if (!this.newItem.editing) {
          body = {
            news: [this.newItem]
          };
          result = await this.MainAPI.saveEntities('courses', body);
        } else {
          body = {
            updateds: [this.newItem]
          };
          result = await this.MainAPI.updateEntities('courses', body);
        }
        if (!result.success) {
          Swal.fire({
            text: result.message,
            icon: 'error'
          });
          return;
        }
        Swal.fire({
          text: 'Se realizo correctamente la operación',
          icon: 'success'
        });
        break;
      case 'academic_period':
        if (!this.newItem.editing) {
          body = {
            news: [this.newItem]
          };
          result = await this.MainAPI.saveEntities('academic_periods', body);
          let periodSelected = this.periods.find((p: any) => p.id === this.newItem.period_id);
          
          let periodInserted = result.data.find((d: any) => d.code === this.newItem.code);
          
          let bodyAcademicPeriodDetail: any = {
            news: Array(periodSelected.quantity).fill(0).map((_, i) => { 
              return { 
                academic_period_id: periodInserted.id, 
                name: `${this.romanNumbers[i + 1]} ${periodSelected.name}`.toUpperCase(),
                order_num: i + 1
              }
            })
          };

          let resultAcademicPeriodDetail: any = await this.MainAPI.saveEntities('academic_period_details', bodyAcademicPeriodDetail);
          console.log(resultAcademicPeriodDetail);
        } else {
          body = {
            updateds: [this.newItem]
          };
          result = await this.MainAPI.updateEntities('academic_periods', body);
        }
        if (!result.success) {
          Swal.fire({
            text: result.message,
            icon: 'error'
          });
          return;
        }
        Swal.fire({
          text: 'Se realizo correctamente la operación',
          icon: 'success'
        });
        break;
      default:
        break;
    }
    this.ngOnInit();
    this.toggleSidebar(this.newItem.typeSelected);
  }

  async saveDetail(type: string, item: any) {
    let result;
    let body: any = {
      news: []
    };
    switch (type) {
      case 'grade_in_academic_period':
        console.log(item);
        let grade_in_academic_periods = item.grades.filter((g: any) => g.selected).map((g: any) => {
          return {
            academic_period_id: item.id,
            grade_id: g.id,
            vacancies: g.vacancies
          };
        })
        body = {
          news: grade_in_academic_periods
        };
        result = await this.MainAPI.saveEntities('grade_in_academic_periods', body);
        
        if (!result.success) {
          Swal.fire({
            text: result.message,
            icon: 'error'
          });
          return;
        }
        Swal.fire({
          text: 'Se realizo correctamente la operación',
          icon: 'success'
        });
        this.getStudentsInGrade();
        break;
      default:
        break;
    }
  }

  toggleChangeCurrent(item: any) {
    item.isCurrent = !item.isCurrent;
  }
  
  toggleSelectGrade(grade: any) {
    grade.selected = !grade.selected;
    if (!grade.selected) {
      grade.vacancies = undefined;
    }
  }

  async toggleAvailableAcademicPeriod(academicPeriod: any) {
    let lastAcademicPeriod: any = this.academicPeriods.find((a: any) => a.is_current);
    let body: any = {};
    if (lastAcademicPeriod) {
      let lastCurrentAcademicPeriod: any = JSON.parse(JSON.stringify(lastAcademicPeriod));
      lastCurrentAcademicPeriod.is_current = false;
      body.updateds = [lastCurrentAcademicPeriod];
      let resultLastCurrentAcademicPeriod: any = await this.MainAPI.updateEntities('academic_periods', body);
      if (!resultLastCurrentAcademicPeriod.success) {
        Swal.fire({
          text: resultLastCurrentAcademicPeriod.message,
          icon: 'error'
        });
        return;
      }
      lastAcademicPeriod.is_current = false;
    } 
    let newCurrentAcademicPeriod = JSON.parse(JSON.stringify(academicPeriod));
    newCurrentAcademicPeriod.is_current = true;
    body.updateds = [newCurrentAcademicPeriod];
    let resultCurrentAcademicPeriod: any = await this.MainAPI.updateEntities('academic_periods', body);
    if (!resultCurrentAcademicPeriod.success) {
      Swal.fire({
        text: resultCurrentAcademicPeriod.message,
        icon: 'error'
      });
      return;
    }
    academicPeriod.is_current = true;
    this.toggleSidebar('')
    this.getInitialVarsToEnrollment();
  }

  toggleRetirementStudent(student: any) {
    console.log(student);
  }

  async searchStudent() {
    console.log(this.filter.enrollment);
    let resultAllStudents: any = await this.MainAPI.getEntitiesBy('students', {});
    this.studentFounds = resultAllStudents.data.filter((s: any) => `${s.code} ${s.father_last_name} ${s.mother_last_name} ${s.names}`.toLocaleLowerCase().includes(this.filter.enrollment.textToSearch));
    console.log(this.studentFounds);
  }

  selectStudentToEnrollment(student: any) {
    console.log(this.newItem);
    console.log(student);
    this.studentToEnrollment = {
      student: student,
      student_id: student.id
    };
  }

  async enrollmentStudent() {
    let body: any = {
      news: [
        {
          student_id: this.studentToEnrollment.student.id,
          grade_in_academic_period_id: this.newItem.grade_in_academic_period_id,
          obs: this.studentToEnrollment.obs
        }
      ]
    };
    let result: any = await this.MainAPI.saveEntities('students_in_grade', body);
    if (!result.success) {
      Swal.fire({
        text: result.message,
        icon: 'error'
      });
      return;
    }
    Swal.fire({
      text: 'Se realizo la matricula correctamente',
      icon: 'success'
    });
    this.toggleSidebar(this.newItem.typeSelected);
    this.getStudentsInGrade();
  }

  async toggleAddCourse(course: any, parent: any) {
    course.selected = !course.selected;
    console.log(course);
    console.log(parent);
    let body: any = {
      news: [
        {
          id: course.id,
          grade_in_academic_period_id: parent.grade_in_academic_period_id,
          course_id: course.id
        }
      ]
    }
    let result: any;
    if (course.selected) {
      console.log(body);
      result = await this.MainAPI.saveEntities('courses_in_grade', body);
      let courseInserted: any = result.data.find((r: any) => r.grade_in_academic_period_id === parent.grade_in_academic_period_id && r.course_id === course.id);
      if (courseInserted) {
        course.courses_in_grade_id = courseInserted.id;
      }
    } else {
      result = await this.MainAPI.deleteEntities('courses_in_grade', body);
    }
  }

}
