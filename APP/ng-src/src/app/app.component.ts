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
  periods: any[] = [];
  grades: any[] = [];
  gradeInAcademicPeriods: any[] = [];
  courses: any[] = [];
  academicPeriods: any[] = [];
  filter: any = {
    students: {
      text: undefined
    },
    academic_periods: {
      text: undefined
    },
  };

  showForm: boolean = false;
  newItem: any;

  ngOnInit(): void {
    console.log("Iniciando proyecto");
    this.getTypes();
    this.getStudents();
    this.getPeriods();
    this.getGrades();
    this.getCourses();
    
  }

  async getTypes() {
    let resultGenders = await this.MainAPI.getEntitiesBy('types', {filter: {type: "GENERO"}});
    this.genders = resultGenders.data;
    
    let resultStudentStatus = await this.MainAPI.getEntitiesBy('types', {filter: {type: "ESTADO-DE-ESTUDIANTE"}});
    this.studentStatus = resultStudentStatus.data;
  }

  async getPeriods() {
    let result: any = await this.MainAPI.getEntitiesBy('periods', {filter: {}});
    console.log(result);
    this.periods = result.data;
  }
  
  async getGrades() {
    let result: any = await this.MainAPI.getEntitiesBy('grades', {filter: [{}]});
    this.grades = result.data;
    this.getGradesInAcademicPeriods();
    this.getAcademicPeriods();
  }

  async getCourses() {
    let result: any = await this.MainAPI.getEntitiesBy('courses', {filter: [{}]});
    this.courses = result.data;
  }

  async getGradesInAcademicPeriods() {
    let result: any = await this.MainAPI.getEntitiesBy('grade_in_academic_periods', {filter: [{}]});
    this.gradeInAcademicPeriods = result.data;
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
        }
      });
    });
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

}
