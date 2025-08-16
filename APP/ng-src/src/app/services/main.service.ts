import { Injectable } from '@angular/core';
import { API_URI, messageAlert } from '../constants';
import { HttpClient } from '@angular/common/http';

@Injectable({
  providedIn: 'root'
})
export class MainService {

  constructor(
    private Http: HttpClient
  ) { }

  uri: string = API_URI;

  async getEntitiesBy(entity: string, body: any) {
    try {
      let result: any = await this.Http.post(`${this.uri}/${entity}/by`, body).toPromise();
      return result;
    } catch (error: any) {
      messageAlert(null, `${error}`, 'error');
    }
  }

  async saveEntities(entity: string, body: any) {
    try {
      let result: any = await this.Http.post(`${this.uri}/${entity}/create`, body).toPromise();
      return result;
    } catch (error: any) {
      messageAlert(null, `${error}`, 'error');
    }
  }

  async updateEntities(entity: string, body: any) {
    try {
      let result: any = await this.Http.put(`${this.uri}/${entity}/update`, body).toPromise();
      return result;
    } catch (error: any) {
      messageAlert(null, `${error}`, 'error');
    }
  }
}
