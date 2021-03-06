#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

class CopyProjectsController < ApplicationController
  before_action :find_project
  before_action :authorize

  def copy
    request_params = params
                       .permit(:send_notifications, only: [])
                       .to_h
                       .merge(target_project_params: target_project_params)
    call = Projects::EnqueueCopyService
      .new(user: current_user, model: @project)
      .call(request_params)

    if call.success?
      job = call.result
      copy_started_notice
      redirect_to job_status_path job.job_id
    else
      @copy_project = call.result
      @errors = call.errors
      render action: copy_action
    end
  end

  def copy_project
    @copy_project = Projects::CopyService
      .new(user: current_user, source: @project)
      .call(target_project_params: target_project_params, attributes_only: true)
      .result

    render action: copy_action
  end

  private

  def target_project_params
    params[:project] ? permitted_params.project.to_h : {}
  end

  def copy_action
    from = (%w(admin settings).include?(params[:coming_from]) ? params[:coming_from] : 'settings')

    "copy_from_#{from}"
  end

  def origin
    params[:coming_from] == 'admin' ? projects_path : settings_generic_project_path(@project.id)
  end

  def copy_started_notice
    flash[:notice] = I18n.t('copy_project.started',
                            source_project_name: @project.name,
                            target_project_name: permitted_params.project[:name])
  end
end
